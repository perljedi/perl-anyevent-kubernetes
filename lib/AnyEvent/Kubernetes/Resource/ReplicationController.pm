package AnyEvent::Kubernetes::Resource::ReplicationController;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

has spec => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

return 42;
