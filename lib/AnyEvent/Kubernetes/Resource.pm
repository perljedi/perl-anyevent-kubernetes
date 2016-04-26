package AnyEvent::Kubernetes::Resource;

use strict;
use warnings;

use Moose;

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


__PACKAGE__->meta->make_immutable;

return 42;
