package AnyEvent::Kubernetes::Resource::Service;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

with 'AnyEvent::Kubernetes::Resource::Role::Status';
with 'AnyEvent::Kubernetes::Resource::Role::Spec';
with 'AnyEvent::Kubernetes::Resource::Role::Updatable';

__PACKAGE__->meta->make_immutable;

return 42;
