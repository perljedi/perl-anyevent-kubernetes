package AnyEvent::Kubernetes::Resource::Namespace;

use strict;
use warnings;

use Moose;
use MooseX::Aliases;
use URI;

extends 'AnyEvent::Kubernetes::Resource';
with    'AnyEvent::Kubernetes::Role::ResourceFetcher';

=head1 NAME

AnyEvent::Kubernetes::Resource::Namespace

=head1 Methods

=head3 list_pods

Fetches a list of all pods in the namespace.

=cut

sub list_pods {
    my $self = shift;
    $self->_fetch_resource('pods', @_);
}

=head3 get_pod

Fetch a specific pod by name

=cut

sub get_pod {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('pods/'.$name, @_);
}

=head3 list_services

Fetches a list of all services in the namespace.

=cut

sub list_services {
    my $self = shift;
    $self->_fetch_resource('services', @_);
}

=head3 get_service

Fetch a specific service by name

=cut

sub get_service {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('services/'.$name, @_);
}

=head3 list_replication_controllers (aliased as list_rc)

Fetches a list of all replication controllers in the namespace.

=cut

sub list_replication_controllers {
    my $self = shift;
    $self->_fetch_resource('replicationcontrollers', @_);
}
alias list_rc => 'list_replication_controllers';

=head3 get_replication_controller (aliased as get_rc)

Fetch a specific replication controller by name

=cut

sub get_replication_controller {
    my $self = shift;
    my $name = shift;
    print "Getting rc $name\n";
    $self->_fetch_resource('replicationcontrollers/'.$name, @_);
}
alias get_rc => 'get_replication_controller';

=head3 list_events

List events

=cut

sub list_events {
    my $self = shift;
    $self->_fetch_resource('events', @_);
}

=head3 get_event

Fetch a specific event by name/id

=cut

sub get_event {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('events/'.$name, @_);
}

=head3 list_endpoints

List endpoints

=cut

sub list_endpoints {
    my $self = shift;
    $self->_fetch_resource('endpoints', @_);
}

=head3 get_endpoint

Fetch a specific endpoint by name/id

=cut

sub get_endpoint {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('endpoints/'.$name, @_);
}

=head3 list_secrets

List secrets

=cut

sub list_secrets {
    my $self = shift;
    $self->_fetch_resource('secrets', @_);
}

=head3 get_secret

Fetch a specific secret by name

=cut

sub get_secret {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('secrets/'.$name, @_);
}

=head3 list_service_accounts

List service accounts

=cut

sub list_service_accounts {
    my $self = shift;
    $self->_fetch_resource('serviceaccounts', @_);
}

=head3 get_service_account

Fetch a specific service account by name

=cut

sub get_service_account {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('serviceaccounts/'.$name, @_);
}

__PACKAGE__->meta->make_immutable;

return 42;
