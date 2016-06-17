package AnyEvent::Kubernetes::Resource::Node;

use strict;
use warnings;

use Moose;

extends 'AnyEvent::Kubernetes::Resource';
with 'AnyEvent::Kubernetes::Resource::Role::Status';
with 'AnyEvent::Kubernetes::Resource::Role::Spec';

=head1 NAME

AnyEvent::Kubernetes::Resource::Node

=cut


__PACKAGE__->meta->make_immutable;

return 42;
