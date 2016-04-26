package AnyEvent::Kubernetes::Resource::ServiceAccount;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

has secrets => (
    is  => 'rw',
    isa => 'ArrayRef[HashRef]',
);

__PACKAGE__->meta->make_immutable;

return 42;
