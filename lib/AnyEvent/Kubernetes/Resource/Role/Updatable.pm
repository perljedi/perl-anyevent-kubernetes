package AnyEvent::Kubernetes::Resource::Role::Updatable;
use strict;
use warnings;

use Moose::Role;
with 'AnyEvent::Kubernetes::Role::ResourceFetcher';

sub update {
    my $self = shift;
    my(%options) = @_;
    my $uri = URI->new($self->api_access->url.$self->metadata->{selfLink});
    $self->api_access->handle_simple_request(PUT => $uri, body => $self->json->encode($self->as_hashref), %options);
}

return 42;
