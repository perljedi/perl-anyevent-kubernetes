package AnyEvent::Kubernetes::Resource::ReplicationController;

use strict;
use warnings;

use Moose;
use AnyEvent;
use UUID::Tiny qw(:std);
use Clone qw(clone);

extends 'AnyEvent::Kubernetes::Resource';
with 'AnyEvent::Kubernetes::Resource::Role::Spec';
with 'AnyEvent::Kubernetes::Resource::Role::HasPods';
with 'AnyEvent::Kubernetes::Resource::Role::Updatable';

=head1 NAME

AnyEvent::Kubernetes::Resource::ReplicationController

=cut

sub scale {
    my $self = shift;
    my $replicas = shift;
    my(%options) = @_;
    my $interval = delete $options{update_interval} || 5;
    my $timeout  = delete $options{timeout} || 120;
    my $type = $self->spec->{replicas} < $replicas ? 'up' : 'down';
    $self->spec->{replicas} = $replicas;
    my $cb = delete $options{onSuccess};
    my $st = time;
    my(%pods) = ();
    my $seen_delete = 0;
    $options{onSuccess} = sub {
        my $cancel;
        $cancel = $self->get_pods(onChange => sub {
            my($pod, $action) = @_;
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
            if(scalar(keys %pods) == $replicas && ($type eq 'up' || $seen_delete)){
                $cb->('scalled') if($cb);
                $cancel->();
            }
        }, error=>$options{error})
    };
    $self->update(%options);
}

sub rolling_update {
    my($self) = shift;
    my(%options) = @_;

    my $new_raw = clone($self->as_hashref);

    if(! $self->spec->{selector}{deployment}){
        my $old_deploy = create_uuid_as_string();
        $self->spec->{selector}{deployment} = $old_deploy;
        $self->spec->{template}{metadata}{labels}{deployment} = $old_deploy;
        $self->update();
    }
    $new_raw->{spec}{replicas} = 0;

    my $deployment_id = create_uuid_as_string();
    $new_raw->{metadata}{name} .= $deployment_id;
    $new_raw->{metadata}{labels}{deployment} = $deployment_id;
    $new_raw->{spec}{selector}{deployment} = $deployment_id;
    $new_raw->{spec}{template}{metadata}{labels}{deployment} = $deployment_id;

    delete $new_raw->{metadata}{creationTimestamp};
    delete $new_raw->{metadata}{uid};
    delete $new_raw->{metadata}{selfLink};
    delete $new_raw->{spec}{securityContext};

    my($scale_up, $scale_down, $clean_up, $new_rc);

    $scale_up = sub {
        $new_rc->scale($new_rc->spec->{replicas} + 1, onSuccess => $scale_down);
    };

    $scale_down = sub {
        $self->scale($self->spec->{replicas} - 1, onSuccess=> sub {
            if($self->spec->{replicas} > 0){
                $scale_up->();
            }else{
                $clean_up->();
            }
        });
    };

    $clean_up = sub {
        $new_rc->metadata->{name} = $self->metadata->{name};
        $self->delete(onSuccess => sub {
            $new_rc->update(onSuccess => sub {
                $options{cb}->($new_rc);
            }, error => sub {use Data::Dumper; print Dumper(@_)."\n"});
        }, error => sub {use Data::Dumper; print Dumper(@_)."\n"});
    };
    my $uri = URI->new_abs("..", $self->api_access->url.$self->metadata->{selfLink});
    $self->api_access->handle_simple_request(
        POST      => $uri.'replicationcontrollers',
        body      => $self->json->encode($new_raw),
        onSuccess => sub {
            $new_rc = shift;
            $scale_up->();
        },
        error => $options{error},
    );
}

__PACKAGE__->meta->make_immutable;

return 42;
