package AnyEvent::Kubernetes::Resource::Secret;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

with 'AnyEvent::Kubernetes::Resource::Role::Updatable';

=head1 NAME

AnyEvent::Kubernetes::Resource::Secret

=cut


has data => (
    is   => 'rw',
    isa  => 'HashRef',
);

has type => (
    is   => 'rw',
    isa  => 'Str',
);

around "as_hashref" => sub {
	my ($orig, $self) = @_;
	my $ref = $self->$orig;
	$ref->{data} = $self->data;
    $ref->{type} = $self->type;
	return $ref;
};

__PACKAGE__->meta->make_immutable;

return 42;
