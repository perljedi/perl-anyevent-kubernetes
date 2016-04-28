package AnyEvent::Kubernetes::Resource::Endpoints;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

has subsets => (
    is  => 'ro',
    isa => 'ArrayRef[HashRef]',
);

around "as_hashref" => sub {
	my ($orig, $self) = @_;
	my $ref = $self->$orig;
	$ref->{subsets} = $self->subsets;
	return $ref;
};

__PACKAGE__->meta->make_immutable;

return 42;
