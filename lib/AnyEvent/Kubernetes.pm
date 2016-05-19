package AnyEvent::Kubernetes;
# ABSTRACT: An object oriented asynchronus interface to the REST API's provided by kubernetes

use strict;
use warnings;

use Moose;
use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::Kubernetes::ResourceFactory;
use AnyEvent::Kubernetes::APIAccess;
use YAML::XS;
use syntax 'try';

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

has metadata => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    builder  => '_build_metadata',
);

has default_namespace => (
    is      => 'rw',
    isa     => 'AnyEvent::Kubernetes::Resource::Namespace',
    builder => '_build_default_namespace',
    lazy    => 1,
    handles => [qw(
        list_pods
        list_services
        list_replication_controllers
        list_rc
        list_events
        list_endpoints
        list_secrets
        get_rc
        get_service
        get_pod
        get_event
    )],
);

with 'AnyEvent::Kubernetes::Role::JSON';
with 'AnyEvent::Kubernetes::Role::ResourceFetcher';

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
    $self->_fetch_resource('namespaces', @_);
}

sub get_namespace {
    my $self = shift;
    my $namespace = shift;

    $self->_fetch_resource('namespaces/'.$namespace, @_);
}

sub list_service_accounts {
    my $self = shift;
    $self->_fetch_resource('serviceaccounts', @_);
}

sub list_nodes {
    my $self = shift;
    $self->_fetch_resource('nodes', @_);
}

sub get_node {
    my $self = shift;
    my $node = shift;

    $self->_fetch_resource('nodes/'.$node, @_);
}

sub create {
    my $self = shift;
    my $file_or_object = shift;
    my(%options) = @_;
    my $object;

    if(ref $file_or_object){
        $object = $file_or_object;
    }else{
        open(my $fh, '<', $file_or_object) || die "Couldn't open supplied file: $!\n";
        my $string = do { local $/; <$fh> };
        close($fh);
        if($file_or_object =~ m/js(?:on)?$/) {
            $object = $self->json->decode($string);
        }
        else {
            $object = YAML::XS::Load $string;
        }
    }
    my $url;
    if($object->{kind} eq 'Namespace'){
        $url = $self->api_access->url.'/api/v1/namespaces';
    }else{
        $url = $self->api_access->url.'/api/v1/namespaces/default/'.lc($object->{kind}).'s'
    }
    $self->api_access->handle_simple_request(
        POST => $url,
        body => $self->json->encode($object),
        %options
    );
}

sub _build_metadata {
    return {
        selfLink  => '/api/v1'
    }
}

sub _build_default_namespace {
    my $self = shift;
    return $self->api_access->handle_simple_request(GET => $self->api_access->url.'/api/v1/namespaces/default', return=>1);
}

__PACKAGE__->meta->make_immutable;

return 42;
