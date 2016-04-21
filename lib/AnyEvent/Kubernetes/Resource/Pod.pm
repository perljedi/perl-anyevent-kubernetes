package AnyEvent::Kubernetes::Resource::Pod;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

__PACKAGE__->meta->make_immutable;

return 42;
