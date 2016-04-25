package AnyEvent::Kubernetes::ResourceFactory;
use strict;
use warnings;

use Moose;
use AnyEvent::Kubernetes::Resource;
use AnyEvent::Kubernetes::ResourceList;
use AnyEvent::Kubernetes::Resource::Namespace;
use AnyEvent::Kubernetes::Resource::Pod;
use AnyEvent::Kubernetes::Resource::Service;
use AnyEvent::Kubernetes::Resource::ReplicationController;

sub get_resource {
    my($invocant, %params) = @_;

    if($params{kind} eq 'Namespace'){
        return AnyEvent::Kubernetes::Resource::Namespace->new(%params);
    }
    elsif($params{kind} eq 'Pod'){
        return AnyEvent::Kubernetes::Resource::Pod->new(%params);
    }
    elsif($params{kind} eq 'ReplicationController'){
        return AnyEvent::Kubernetes::Resource::ReplicationController->new(%params);
    }
    elsif($params{kind} eq 'Service'){
        return AnyEvent::Kubernetes::Resource::Service->new(%params);
    }
    elsif($params{kind} =~ m/List$/){
        return AnyEvent::Kubernetes::ResourceList->new(%params);
    }
    else {
        return AnyEvent::Kubernetes::Resource->new(%params);
    }
}

__PACKAGE__->meta->make_immutable;

return 42;
