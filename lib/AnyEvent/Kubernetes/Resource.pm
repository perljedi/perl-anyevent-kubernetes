package AnyEvent::Kubernetes::Resource;

use strict;
use warnings;

use Moose;

has api_access => (
    is       => 'ro',
    isa      => 'AnyEvent::Kubernetes::APIAccess',
    required => 1,
);

has metadata => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

with 'AnyEvent::Kubernetes::Role::JSON';

__PACKAGE__->meta->make_immutable;

return 42;
