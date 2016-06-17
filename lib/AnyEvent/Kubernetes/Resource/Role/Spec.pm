package AnyEvent::Kubernetes::Resource::Role::Spec;

use strict;
use warnings;

use Moose::Role;

=head1 NAME

AnyEvent::Kubernetes::Resource::Role::Spec

=cut

has spec => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

around "as_hashref" => sub {
	my ($orig, $self) = @_;
	my $ref = $self->$orig;
	$ref->{spec} = $self->spec;
	return $ref;
};

return 42;
