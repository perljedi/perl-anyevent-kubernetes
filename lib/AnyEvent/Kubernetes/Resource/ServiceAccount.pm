package AnyEvent::Kubernetes::Resource::ServiceAccount;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';

has secrets => (
    is  => 'rw',
    isa => 'ArrayRef[HashRef]',
);

around "as_hashref" => sub {
	my ($orig, $self) = @_;
	my $ref = $self->$orig;
	$ref->{secrets} = $self->secrets;
	return $ref;
};

__PACKAGE__->meta->make_immutable;

return 42;
