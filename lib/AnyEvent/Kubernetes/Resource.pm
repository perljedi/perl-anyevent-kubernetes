package AnyEvent::Kubernetes::Resource;

use strict;
use warnings;

use Moose;

has api_access => (
    is       => 'r',
    isa      => 'AnyEvent::Kubernetes::APIAccess',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

return 42;
