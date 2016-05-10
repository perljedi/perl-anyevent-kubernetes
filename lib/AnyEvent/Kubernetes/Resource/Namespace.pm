package AnyEvent::Kubernetes::Resource::Namespace;

use strict;
use warnings;

use Moose;
use MooseX::Aliases;
use URI;

extends 'AnyEvent::Kubernetes::Resource';
with    'AnyEvent::Kubernetes::Role::ResourceFetcher';

sub list_pods {
    my $self = shift;
    $self->_fetch_resource('pods', @_);
}

sub get_pod {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('pods/'.$name, @_);
}

sub list_services {
    my $self = shift;
    $self->_fetch_resource('services', @_);
}

sub get_service {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('services/'.$name, @_);
}

sub list_replication_controllers {
    my $self = shift;
    $self->_fetch_resource('replicationcontrollers', @_);
}
alias list_rc => 'list_replication_controllers';

sub get_replication_controller {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('replicationcontrollers/'.$name, @_);
}
alias get_rc => 'get_replication_controller';

sub list_events {
    my $self = shift;
    $self->_fetch_resource('events', @_);
}

sub get_event {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('events/'.$name, @_);
}

sub list_endpoints {
    my $self = shift;
    $self->_fetch_resource('endpoints', @_);
}

sub get_endpoint {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('endpoints/'.$name, @_);
}


sub list_secrets {
    my $self = shift;
    $self->_fetch_resource('secrets', @_);
}

sub get_secret {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('secrets/'.$name, @_);
}


sub list_service_accounts {
    my $self = shift;
    $self->_fetch_resource('serviceaccounts', @_);
}

sub get_service_account {
    my $self = shift;
    my $name = shift;
    $self->_fetch_resource('serviceaccounts/'.$name, @_);
}


__PACKAGE__->meta->make_immutable;

return 42;
