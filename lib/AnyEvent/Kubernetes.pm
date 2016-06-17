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

=head1 NAME

AnyEvent::Kubernetes

=head1 Description

AnyEvent::Kubernetes is an event driven interface to the Kubernetes REST API. The primary motivation for building
this module is to expose some more advanced features of the API (watching) and allow some more advanced additional
functionality (rolling-update), which really only make sense in an event driven set up.

=head1 SYNOPSIS

  my $kube = AnyEvent::Kubernetes->new(url=>'http://127.0.0.1:8080', username=>'dave', password=>'davespassword');
  $kube->list_pods(onSuccess => sub{
    my($pod_list) = @_;
  }, onError => sub {
    my($message) = @_;
    print "Ohh no!  An error occured: ".$message."\n";
  });

  $kube->list_pods(onChange => sub {
    my($pod) = @_;
  });

  $kube->get_rc('my-controller', onSuccess => sub {
    my $rc = shift;
    $rc->spec->{template}{containers}[0]{image} = 'myimages/image:release-12345';
    $rc->rolling_update(onSuccess=> sub {
        print "Woot! rolling update successfull\n";
    });
  });

=head1 Standard Arguments

Most methods take a couple of standard arguments.

=over

=item onSuccess => sub { ... }

onSuccess is accepted by almost all methods, and will be invocked upon successfull completion of the operation.
The supplied callback will be passed the involved oject, either a Resource object or a ResourceList Object.

=item onError => sub {  }

onError is also accepted by almost all methods, and is simply the converse of onSuccess.
The supplied callback will be passed a message which could be a simple string, or a hasref.
Simple strings generally indicate a communication failure with the api server, a hashref would be the decoded response from
kubernetes.

=item onChange => sub { ... }

onChange is an optional argument to all "list" methods which will fundementally change the behavoir of the function,
and should not be used in conjunction with onSuccess.  When onChange is supplied, the resulting connection to kubernetes
api will be a streaming connection sending real time updates for changes to any of the resources in the resulting list.
The onChange callback will be evoked continuously every time a resource changes, and will be passed the resource object
which changed, as well as the type of change (ADDED|MODIFIED|DELETED). It will also be called once for each item in the list
(with a type of ADDED) immediately which will allow the building of an initial list.

When onChange is supplied, the method will return a code reference which is effectively a cancellation callback. When you
want to stop listening for changes to the list, invoke this callback and the persisten connection to the API server
will be terminated, and the onChange callback will no longer be called.

=back

=head2 List Filtering arguments

All "list" methods accept the following parameters to filter the list of returned resources.

=over

=item labels => {}

The supplied hashref of key value pairs will be translated into labelSelector's for the kubernetes api.

=item fields => {}

The supplied hashref of key value pairs will be translated into fieldSelector's for the kubernetes api.

=back

=head1 Methods

=head3 new

Creates a new instance of AnyEvent::Kubernetes.

Required Arguments:

=over

=item url

The base url to the kubernetes api. For Example http://172.18.8.101:8080/api/v1

=back

Optional Arguments:

=over

=item username, password

Credentials used to authenticate to the kubernetes API server.

=item ssl_cert_file, ssl_key_file, ssl_ca_file

SSL certificate key and CA for client cert based authentication to kubernetes

=item ssl_verify

Boolean flag to verify the source of the kubenetes server certificate. Defaults to true.

=item token

An authorization token to be sent to kubernetes

=back

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

=head3 list_namespaces

List kubernetes name spaces.

=cut

sub list_namespaces {
    my $self = shift;
    $self->_fetch_resource('namespaces', @_);
}

=head3 get_namespace("default")

Fetch a specific namespace by name

=cut


sub get_namespace {
    my $self = shift;
    my $namespace = shift;

    $self->_fetch_resource('namespaces/'.$namespace, @_);
}

=head3 list_service_accounts

List kubernetes name spaces.

=cut


sub list_service_accounts {
    my $self = shift;
    $self->_fetch_resource('serviceaccounts', @_);
}

=head3 list_nodes

List kubernetes minions/nodes.

=cut

sub list_nodes {
    my $self = shift;
    $self->_fetch_resource('nodes', @_);
}

=head3 get_node("myNode")

Get a specific node.

=cut

sub get_node {
    my $self = shift;
    my $node = shift;

    $self->_fetch_resource('nodes/'.$node, @_);
}

=head3 create(FILENAME | {})

Create a new kubernetes resource. This method accepts either a path to a json or yaml file
or a hashref of the equivelent datastructure.

=cut

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

=head2 Delegated Methods

The following methods can be called on the kube object and will be automatically delegated to the default namespace

=over

=item list_pods

=item list_services

=item list_replication_controllers

=item list_rc

=item list_events

=item list_endpoints

=item list_secrets

=item get_rc

=item get_service

=item get_pod

=item get_event

=back

See L<AnyEvent::Kubernetes::Rescource::Namepsace> for details on each of these.


=cut

return 42;
