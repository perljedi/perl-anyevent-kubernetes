package AnyEvent::Kubernetes::Resource::Endpoints;

use strict;
use warnings;

use Moose;

=head1 NAME

AnyEvent::Kubernetes::Resource::Endpoints

=cut


extends 'AnyEvent::Kubernetes::Resource';

with 'AnyEvent::Kubernetes::Resource::Role::Updatable';

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
