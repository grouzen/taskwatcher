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

    sub add_task
    {
        my ($self, $taskname, $taskdescr) = @_;
        
        my $task = $self->get_task($taskname);

        if(!defined($task)) {
            $self->{doc}->{tasks}->{$taskname} = {
                descr => $taskdescr,
                time => time(),
                create_time => time(),
                done => 0
            };

            print $self->{printer}->p("Add task: $taskname\n");
            
            $self->write();
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
        my ($self) = @_;
        my $tasks = $self->{doc}->{tasks};

        print $self->{printer}->p("Tasks:\n");

        foreach my $taskname (keys(%{$tasks})) {
            my $task = $self->get_task($taskname);
            
            print $self->{printer}->p($taskname);
            print $self->{printer}->p(" (" . $task->get_descr . ")") if defined($task->get_descr);
            print "\n";

            print $self->{printer}->p("  spent time: " . $self->{printer}->p($self->{printer}->human_time($task->delta_time)) . "\n");
            
        }
    }

}

1;

