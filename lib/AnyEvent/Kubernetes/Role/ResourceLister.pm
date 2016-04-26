package AnyEvent::Kubernetes::Role::ResourceLister;

use strict;
use warnings;

use Moose::Role;
use AnyEvent::HTTP;
use AnyEvent::Kubernetes::ResourceFactory;

requires 'api_access';
requires 'metadata';

sub _list_resource {
    my $self = shift;
    my $resource = shift;
    my(%options) = @_;
    my(%access_options) = $self->api_access->get_request_options;

    my $uri = URI->new($self->api_access->url.'/'.$self->metadata->{selfLink}.'/'.$resource);
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

    http_request
        GET => $uri,
        %access_options,
        sub {
            my($body, $headers) = @_;
            my $resourceList = $self->json->decode($body);
            if($options{cb}){
                $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(%$resourceList, api_access=>$self->api_access));
            }
        };
}

sub _build_selector_from_hash {
	my($self, $select_hash) = @_;
	my(@selectors);
	foreach my $label (keys %{ $select_hash }){
		push @selectors, $label.'='.$select_hash->{$label};
	}
	return \@selectors;
}


return 42;
