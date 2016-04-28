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
    my($cv, $resourceList);
    my $return = delete $options{return};
    if($return){
        $cv = AnyEvent->condvar;
    }

    my(%access_options) = $self->api_access->get_request_options;

    my $uri = URI->new($self->api_access->url.$self->metadata->{selfLink}.'/'.$resource);
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

    http_request
        GET => $uri,
        %access_options,
        sub {
            my($body, $headers) = @_;
            if($headers->{Status} < 200 || $headers->{Status} > 400){
                if($options{error}){
                    try {
                        my $message = $self->json->decode($body);
                        $options{error}->($message);
                    } catch ($e) {
                        $options{error}->($body);
                    }
                }
            }else{
                if($options{cb}){
                    my $resourceHash = $self->json->decode($body);
                    $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(%$resourceHash, api_access => $self->api_access));
                }
            }
            if($cv){
                $cv->send;
            }
        };

    if($cv){
        $cv->recv;
        return $resourceList;
    }
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
