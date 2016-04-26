package AnyEvent::Kubernetes::Resource::Secret;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

has data => (
    is   => 'rw',
    isa  => 'HashRef',
);

has type => (
    is   => 'rw',
    isa  => 'Str',
);

__PACKAGE__->meta->make_immutable;

return 42;
