package AnyEvent::Kubernetes::Resource::ReplicationController;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';
with 'AnyEvent::Kubernetes::Resource::Role::Spec';

__PACKAGE__->meta->make_immutable;

return 42;
