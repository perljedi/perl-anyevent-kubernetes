package AnyEvent::Kubernetes::Role::ResourceCreator;

use strict;
use warnings;

use Moose::Role;

requires 'api_access';

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

return 42;
