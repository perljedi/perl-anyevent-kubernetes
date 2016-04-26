package AnyEvent::Kubernetes::Resource::Endpoints;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

has subsets => (
    is  => 'ro',
    isa => 'ArrayRef[HashRef]',
);

__PACKAGE__->meta->make_immutable;

return 42;
