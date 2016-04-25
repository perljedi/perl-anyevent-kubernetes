package AnyEvent::Kubernetes::Resource::Pod;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

with 'AnyEvent::Kubernetes::Resource::Role::Status';

has spec => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

return 42;
