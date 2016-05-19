package AnyEvent::Kubernetes::Resource::ReplicationController;

use strict;
use warnings;

use Moose;
use AnyEvent;
use UUID::Tiny qw(:std);

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
    my $type = $self->spec->{replicas} < $replicas ? 'up' : 'down';
    $self->spec->{replicas} = $replicas;
    my $cb = delete $options{cb};
    my $st = time;
    my(%pods) = ();
    my $seen_delete = 0;
    $options{cb} = sub {
        my $cancel;
        $cancel = $self->get_pods(change => sub {
            my($pod, $action) = @_;
            print "$action - ".$pod->metadata->{name}." - ".($pod->is_ready ? "ready" : "not-ready")."\n";
            if($action eq 'DELETED'){
                $seen_delete = 1;
                delete $pods{$pod->metadata->{name}} if(exists($pods{$pod->metadata->{name}}));
            }else{
                if($pod->is_ready){
                    $pods{$pod->metadata->{name}} = 1;
                }else{
                    delete $pods{$pod->metadata->{name}} if(exists($pods{$pod->metadata->{name}}));
                }
            }
            print join(", ", keys %pods)." - $type - $seen_delete\n";
            if(scalar(keys %pods) == $replicas && ($type eq 'up' || $seen_delete)){
                print "Cancel == $cancel\n";
                $cb->('scalled') if($cb);
                $cancel->();
            }
            # my($podList) = @_;
            # if(scalar(@{ $podList->all }) == $replicas){
            #     $cb->('scalled') if($cb);
            # }else{
            #     if(time - $st > $timeout){
            #         if($options{error}){
            #             $options{error}->({ message => "Timeout exceeded before reaching requested replica count", timeout=>$timeout, elapsed => time - $st });
            #         }
            #     }
            #     else {
            #         $gaurd = AnyEvent->timer(after => $interval, cb=>$options{cb});
            #     }
            # }
        }, error=>$options{error})
    };
    $self->update(%options);
}

sub rolling_update {
    my($self) = shift;
    my(%options) = @_;
    my $new_raw = $self->as_hashref;
    $new_raw->{spec}{replicas} = 0;
    $new_raw->{metadata}{name} .= create_uuid_as_string();
    delete $new_raw->{metadata}{creationTimestamp};
    delete $new_raw->{metadata}{uid};
    delete $new_raw->{metadata}{selfLink};
    use Data::Dumper; print Dumper($new_raw)."\n";
}

__PACKAGE__->meta->make_immutable;

return 42;
