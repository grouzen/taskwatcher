#
# Copyright (c) 2012 Nedokushev Michael <grouzen.hexy@gmail.com>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

package Local::Taskwatcher::DB; 
{
    
    use strict;
    use utf8;

    use YAML::Tiny;
    
    use Local::Taskwatcher::Task;
    use Local::Taskwatcher::Commit;
    use Local::Taskwatcher::Printer qw(INFO SUCCESS ERROR);
    
    use Data::Dumper;

    use constant {
        UPDATE_INTERVAL => 5
    };
    
    sub new
    {
        my ($class, $file, $printer) = @_;
        
        return undef if !defined($file) || !defined($printer);
        
        my $self = { file => $file, printer => $printer };
        
        return bless($self, $class);
    }

    sub open
    { 
        my $self = shift;
        my $yaml = YAML::Tiny->read($self->{file});

        if(!defined($yaml)) {
            # Create a new yaml file if it doesn't exist.
            $yaml = YAML::Tiny->new();
            
            $yaml->[0]->{current} = '';
            $self->add('create_new_db_file', 'task that created on first launch of the program');

            return undef if !defined($yaml->write($self->file));
        }
        
        $self->{yaml} = $yaml;
        $self->{doc} = $yaml->[0];

        # For calls chaining.
        return $self;
    }

    sub close
    {
        my $self = shift;
        
        $self->file = undef;
        $self->yaml = undef;
        $self->doc =  undef;

        return undef;
    }

    sub write
    {
        my ($self) = @_;

        $self->{yaml}->write($self->{file});
    }

    sub need_update
    {
        my ($self, $ticks) = @_;

        return ($ticks >= UPDATE_INTERVAL ? 1 : 0);
    }

    sub get_task
    {
        my ($self, $taskname) = @_;
        
        my $task = Local::Taskwatcher::Task->new($self->{doc}, $taskname);
        
        return undef if !defined($task);
        return $task;
    }
    
    sub set_descr
    { 
        my ($self, $taskname, $descr) = @_;

        my $task = $self->get_task($taskname);
        if(defined($task)) {
            $task->set_descr($descr);
        
            $self->write();
            print $self->{printer}->p("Description changed for task: $taskname\n");
        } else {
            print $self->{printer}->p("Set description: Task not found: $taskname\n");
        }
        
        return $self;
    }
    
    sub add_task
    {
        my ($self, $taskname, $taskdescr) = @_;
        
        my $task = $self->get_task($taskname);

        if(!defined($task)) {
            my @chain = Local::Taskwatcher::Task->tasks_chain($taskname);
            my $parentname = Local::Taskwatcher::Task->parent_path(@chain);
            
            $task = $self->get_task($parentname);
            if(defined($task)) {
                $task->create_subtask($chain[$#chain]);
                $self->write();

                $self->set_descr($taskname, $taskdescr);

                print $self->{printer}->p("Add task: $taskname\n");
            } else {
                print $self->{printer}->p("Couldn't add subtask to: $parentname: parent doesn't exists\n");
            }
        } else {
            print $self->{printer}->p("Task is already exists: $taskname\n");
        }
        
        return $self;
    }

    sub status
    {
        my ($self, $taskname) = @_;
        my $task = $self->get_task($taskname);
        
        if(defined($task)) {
            print $self->{printer}->p($self->{printer}->human_time($task->delta_time()), SUCCESS) . "\n";
        } else {
            print $self->{printer}->p("Task not found: $taskname\n");
        }

        return $self;
    }

    sub tasks_list
    {
        my ($self, $target_task) = @_;
        
        my $root_task;
        my $task_path = '';

        if(!defined($target_task)) {
            $root_task = $self->get_task('');
        } else {
            $root_task = $self->get_task($target_task);
            $task_path = $target_task . '.';
        }

        my $tasks = $root_task->get_subtasks();

        print $self->{printer}->p("Tasks:\n");

        foreach my $taskname (keys(%{$tasks})) {
            my $task = $self->get_task($task_path . $taskname);
            
            print $self->{printer}->p($taskname . "\n");

            if(defined($task->get_descr)) {
                print $self->{printer}->p("  description: " . $task->get_descr . "\n");
            }

            print $self->{printer}->p("  time: " . $self->{printer}->p($self->{printer}->human_time($task->delta_time)) . "\n");

            my $subtasks = $task->get_subtasks();
            
            if(scalar keys(%{$subtasks}) > 0) {
                print "  subtasks: \n";
                for my $subtask (keys(%{$subtasks})) {
                    my $t = $self->get_task($task_path . $taskname . '.' . $subtask);

                    print $self->{printer}->p("    $subtask:\n");
                    print $self->{printer}->p("        time: " . $self->{printer}->p($self->{printer}->human_time($t->delta_time)) . "\n");
                    if(defined($t->get_descr)) {
                        print $self->{printer}->p("        description: " . $t->get_descr . "\n");
                    }
                }
            }
        }
    }

}

1;

