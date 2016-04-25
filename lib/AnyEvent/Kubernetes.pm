package AnyEvent::Kubernetes;
# ABSTRACT: An object oriented asynchronus interface to the REST API's provided by kubernetes

use strict;
use warnings;

use Moose;
use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::Kubernetes::ResourceFactory;
use AnyEvent::Kubernetes::APIAccess;

=head1 SYNOPSIS

  my $kube = AnyEvent::Kubernetes->new(url=>'http://127.0.0.1:8080', username=>'dave', password=>'davespassword');
  $kube->list_pods(cb => sub{
    my($pod_list) = @_;
  });

  $kube->watch_pods(activity_cb => sub {
    my($pod) = @_;
  })


=cut

has api_access => (
    is       => 'ro',
    isa      => 'AnyEvent::Kubernetes::APIAccess',
    required => 1,
);

has default_namespace => (
    is      => 'rw',
    isa     => 'AnyEvent::Kubernetes::Resource::Namespace',
    builder => '_build_default_namespace',
    lazy    => 1,
    handles => [qw(list_pods)],
);

with 'AnyEvent::Kubernetes::Role::JSON';

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my(%input) = @_;
    my(%access_options) = ();
    foreach my $field (qw(password username token ssl_cert_file ssl_key_file ssl_ca_file ssl_verify url)){
        $access_options{$field} = delete $input{$field} if(exists $input{$field});
    }
    $input{api_access} = AnyEvent::Kubernetes::APIAccess->new(%access_options);
    return $class->$orig(%input);
};

sub list_namespaces {
    my $self = shift;
    my(%options) = @_;
    my(%access_options) = $self->api_access->get_request_options;
    http_request
        GET => $self->api_access->url.'/api/v1/namespaces',
        %access_options,
        sub {
            my($body, $headers) = @_;
            my($namespaceList) = $self->json->decode($body);
            if($options{cb}){
                $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(%$namespaceList, api_access=>$self->api_access));
            }
        };
};

sub _build_default_namespace {
    my $self = shift;
    my(%options) = $self->api_access->get_request_options;
    my $cv = AnyEvent->condvar;
    my $namespace;
    http_request
        GET => $self->api_access->url.'/api/v1/namespaces/default',
        %options,
        sub {
            my($body, $headers) = @_;
            $namespace = $self->json->decode($body);
            $cv->send;
        };
    $cv->recv;
    return AnyEvent::Kubernetes::ResourceFactory->get_resource(%$namespace, api_access => $self->api_access);
}

__PACKAGE__->meta->make_immutable;

return 42;
