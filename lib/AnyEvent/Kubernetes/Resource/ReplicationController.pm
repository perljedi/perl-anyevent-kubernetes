package AnyEvent::Kubernetes::Resource::ReplicationController;

use strict;
use warnings;

use Moose;
use AnyEvent;

extends 'AnyEvent::Kubernetes::Resource';
with 'AnyEvent::Kubernetes::Resource::Role::Spec';
with 'AnyEvent::Kubernetes::Resource::Role::HasPods';
with 'AnyEvent::Kubernetes::Resource::Role::Updatable';

sub scale {
    my $self = shift;
    my $replicas = shift;
    my(%options) = @_;
    my $interval = delete $options{update_interval} || 5;
    my $timeout  = delete $options{timeout} || 120;
    $self->spec->{replicas} = $replicas;
    my $cb = delete $options{cb};
    my $st = time;
    my $gaurd;
    $options{cb} = sub {
        $self->get_pods(cb => sub {
            my($podList) = @_;
            if(scalar(@{ $podList->all }) == $replicas){
                $cb->('scalled') if($cb);
            }else{
                if(time - $st > $timeout){
                    if($options{error}){
                        $options{error}->({ message => "Timeout exceeded before reaching requested replica count", timeout=>$timeout, elapsed => time - $st });
                    }
                }
                else {
                    $gaurd = AnyEvent->timer(after => $interval, cb=>$options{cb});
                }
            }
        }, error=>$options{error})
    };
    $self->update(%options);
}

__PACKAGE__->meta->make_immutable;

return 42;
