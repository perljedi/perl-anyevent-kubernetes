package AnyEvent::Kubernetes::Resource::Role::HasPods;

use strict;
use warnings;

use Moose::Role;
with 'AnyEvent::Kubernetes::Role::ResourceFetcher';

=head1 NAME

AnyEvent::Kubernetes::Resource::Role::HasPods

=cut


sub get_pods {
    my $self = shift;
    my(%options) = @_;
    my $uri = URI->new_abs("../pods", $self->api_access->url.$self->metadata->{selfLink});
    $self->_fetch_resource($uri, %options, labels=>$self->spec->{selector});
}

return 42;
