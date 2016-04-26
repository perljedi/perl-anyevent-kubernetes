package AnyEvent::Kubernetes::Resource::Pod;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

with 'AnyEvent::Kubernetes::Resource::Role::Status';
with 'AnyEvent::Kubernetes::Resource::Role::Spec';

__PACKAGE__->meta->make_immutable;

return 42;
