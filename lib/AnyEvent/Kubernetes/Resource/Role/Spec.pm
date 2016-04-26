package AnyEvent::Kubernetes::Resource::Role::Spec;
use strict;
use warnings;

use Moose::Role;

has spec => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

return 42;
