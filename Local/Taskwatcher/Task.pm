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

package Local::Taskwatcher::Task; 
{
    
    use strict;
    use utf8;

    sub new
    {
        my ($class, $doc, $name) = @_;
        
        return undef if !defined($name) || !defined($doc);
        
        my $self = {};
        bless($self, $class);

        $self->{doc} = $doc;
        $self->{name} = $name;

        my $task = $self->find_task($doc, $name);
        
        return undef if !defined($task);
        
        $self->{task} = $task;

        return $self;
    }

    sub find_task
    {
        my ($self, $doc, $name) = @_;
        
        my $task = undef;
        my @tree = split(/\./, $name);
        
        $task = $doc;

        for(my $i = 0; $i <= $#tree; $i++) {
            $task = $task->{tasks}->{$tree[$i]};
            return undef if !defined($task);
        }

        return $task;
    }

    sub delta_time
    {
        my ($self) = @_;
        
        return $self->{task}->{time} - $self->{task}->{create_time};
    }

    sub set_time
    {
        my ($self, $time) = @_;

        $self->{task}->{time} = $time;
        return $self;
    }

    sub add_delta_time
    {
        my ($self, $piece) = @_;

        $self->{task}->{time} += $piece;
    }

    sub get_time
    {
        my ($self) = @_;

        return $self->{task}->{time};
    }

    sub get_create_time
    {
        my ($self) = @_;

        return $self->{task}->{create_time};
    }

    sub get_descr
    {
        my ($self) = @_;

        return $self->{task}->{descr};
    }

}

1;
