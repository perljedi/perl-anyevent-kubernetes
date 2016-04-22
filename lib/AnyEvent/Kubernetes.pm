package AnyEvent::Kubernetes;
# ABSTRACT: An object oriented asynchronus interface to the REST API's provided by kubernetes

use strict;
use warnings;

use Moose;

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
    is       => 'r',
    isa      => 'AnyEvent::Kubernetes::APIAccess',
    required => 1,
);

has url => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'http://localhost:8080/api/v1'
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my(%input) = @_;
    my(%acces_options) = ();
    foreach my $field (qw(password username token ssl_cert_file ssl_key_file ssl_ca_file ssl_verify)){
        $acces_options{$field} = delete $input{$field} if(exists $input{$field});
    }
    $input{api_access} = AnyEvent::Kubernetes::APIAccess->new($access_options);
    return $class->$orig(%input);
};


__PACKAGE__->meta->make_immutable;

return 42;
