package AnyEvent::Kubernetes::Resource::Event;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

=head1 NAME

AnyEvent::Kubernetes::Resource::Event

=cut


has involvedObject => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

has source => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

has reason => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has message => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has firstTimestamp => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has lastTimestamp => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has count => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

return 42;
