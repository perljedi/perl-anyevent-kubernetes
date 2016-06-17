package AnyEvent::Kubernetes::Resource;

use strict;
use warnings;

use Moose;
use Clone qw(clone);

=head1 NAME

AnyEvent::Kubernetes::Resource

=cut


has api_access => (
    is       => 'ro',
    isa      => 'AnyEvent::Kubernetes::APIAccess',
    required => 1,
);

has metadata => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

has kind => (
    is   => 'ro',
    isa  => 'Str'
);

has apiVersion => (
    is   => 'ro',
    isa  => 'Str'
);

with 'AnyEvent::Kubernetes::Role::JSON';

sub as_hashref
{
    my($self) = @_;

    # Kubernetes will set resourceVersion itself of create
    # Inlcuding it in update operations will cause issues
    my $metadata = $self->metadata;
    delete $metadata->{resourceVersion};

    return {
        inner(),
        apiVersion=>$self->apiVersion,
        kind=>$self->kind,
        metadata=>$self->metadata
    };
}

sub refresh {
    my $self = shift;
    my(%options) = @_;
    my $cb = delete $options{onSuccess};
    $self->_fetch_resource('', %options, onSuccess=> sub {
        my($new_obj) = shift;
        my $updated = $new_obj->as_hashref;
        foreach my $key (grep(!/kind|apiVersion/, keys %$updated)){
            $self->$key(clone($updated->{$key}));
        }
        if($self->can('status')){
            $self->status(clone($new_obj->status));
        }
        $cb->($self);
    });
}

sub delete {
    my $self = shift;
    my(%options) = @_;
    $self->api_access->handle_simple_request(DELETE => $self->api_access->url.$self->metadata->{selfLink}, %options);
}

__PACKAGE__->meta->make_immutable;

return 42;
