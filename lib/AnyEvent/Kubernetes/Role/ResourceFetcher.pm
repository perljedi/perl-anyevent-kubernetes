package AnyEvent::Kubernetes::Role::ResourceFetcher;

use strict;
use warnings;

use Moose::Role;
use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::Kubernetes::ResourceFactory;
use syntax 'try';

requires 'api_access';
requires 'metadata';

sub _fetch_resource {
    my $self = shift;
    my $resource = shift;
    my(%options) = @_;


    my $uri;
    if(ref($resource) && $resource->isa('URI')){
        $uri = $resource
    }
    else {
        $uri = URI->new($self->api_access->url.$self->metadata->{selfLink}.'/'.$resource);
    }
    my(%form) = ();
    $form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
    $form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
    $uri->query_form(%form);

    if($options{change}){
        $self->api_access->handle_streaming_request(GET => $uri, %options);
    }
    else {
        $self->api_access->handle_simple_request(GET => $uri, %options);
    }

}

sub _build_selector_from_hash {
    my($self, $select_hash) = @_;
    my(@selectors);
    foreach my $label (keys %{ $select_hash }){
        push @selectors, $label.'='.$select_hash->{$label};
    }
    return join(',',@selectors);
}


return 42;
