package AnyEvent::Kubernetes::ResourceList;

use strict;
use warnings;

use Moose;

has api_access => (
    is       => 'ro',
    isa      => 'AnyEvent::Kubernetes::APIAccess',
    required => 1,
);

has all => (
    is       => 'rw',
    isa      => 'ArrayRef[AnyEvent::Kubernetes::Resource]',
    required => 1
);

has metadata => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);
has kind     => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has apiVersion => (
    is   => 'ro',
    isa  => 'Str'
);

around BUILDARGS => sub {
    my $orig = shift;
	my $class = shift;
	my(%input) = @_;
    $input{all} = [];
    my $resource_kind = substr($input{kind}, 0, -4);
    foreach my $item (@{ $input{items} }){
        $item->{kind} = $resource_kind;
        $item->{apiVersion}  = $input{apiVersion};
        push @{ $input{all} }, AnyEvent::Kubernetes::ResourceFactory->get_resource(%$item, api_access => $input{api_access});
    }
	return $class->$orig(%input);
};

__PACKAGE__->meta->make_immutable;

return 42;
