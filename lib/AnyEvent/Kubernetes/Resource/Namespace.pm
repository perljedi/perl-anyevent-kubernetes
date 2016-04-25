package AnyEvent::Kubernetes::Resource::Namespace;

use strict;
use warnings;

use Moose;
use AnyEvent::HTTP;
use AnyEvent::Kubernetes::ResourceFactory;

extends 'AnyEvent::Kubernetes::Resource';

sub list_pods {
    my $self = shift;
    $self->_list_resource('pods', @_);
}

sub list_services {
    my $self = shift;
    $self->_list_resource('services', @_);
}

sub list_replicationcontrollers {
    my $self = shift;
    $self->_list_resource('replicationcontrollers', @_);
}

sub _list_resource {
    my $self = shift;
    my $resource = shift;
    my(%options) = @_;
    my(%access_options) = $self->api_access->get_request_options;
    http_request
        GET => $self->api_access->url.'/'.$self->metadata->{selfLink}.'/'.$resource,
        %access_options,
        sub {
            my($body, $headers) = @_;
            my $resourceList = $self->json->decode($body);
            if($options{cb}){
                $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(%$resourceList, api_access=>$self->api_access));
            }
        };
}

__PACKAGE__->meta->make_immutable;

return 42;
