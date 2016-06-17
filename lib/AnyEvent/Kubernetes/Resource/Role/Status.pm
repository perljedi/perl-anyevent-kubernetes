package AnyEvent::Kubernetes::Resource::Role::Status;

use strict;
use warnings;

use Moose::Role;

=head1 NAME

AnyEvent::Kubernetes::Resource::Role::Status

=cut


has status => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

sub is_ready {
    my $self = shift;
    return scalar(grep( { $_->{type} eq 'Ready' && $_->{status} eq 'True' } @{ $self->status->{conditions} } ));
}

return 42;
