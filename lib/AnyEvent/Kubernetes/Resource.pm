package AnyEvent::Kubernetes::Resource;

use strict;
use warnings;

use Moose;

with 'AnyEvent::Kubernetes::Role::APIAccess';

__PACKAGE__->meta->make_immutable;

return 42;
