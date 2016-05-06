package AnyEvent::Kubernetes::APIAccess;
use strict;
use warnings;

use Moose;

use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::Kubernetes::ResourceFactory;
use syntax 'try';

has url => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'http://localhost:8080/api/v1'
);

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has username => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has token => (
    is       => 'ro',
    isa      => 'Str',
    required => 0
);

has ssl_cert_file => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has ssl_key_file => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has ssl_ca_file => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has ssl_verify => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

with 'AnyEvent::Kubernetes::Role::JSON';

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my(%input) = @_;
    if(ref($input{token})){
        if($input{token}->can('getlines')){
            $input{token} = join('', $input{token}->getlines);
        }
        elsif (ref($input{token}) eq 'GLOB') {
            my $fh = $input{token};
            $input{token} = do{ local $/; <$fh>};
        }
    }elsif (exists $input{token} && -f $input{token}) {
        open(my $fh, '<', $input{token});
        $input{token} = do{ local $/; <$fh>};
        close($fh);
    }
    if(! exists $input{api_version}){
        if(exists $input{base_path}){
            if($input{base_path} =~ m{/api/(v[^/]+)}){
                $input{api_version} = $1;
            }
        }
        else {
            $input{api_version}='v1';
        }
    }
    return $class->$orig(%input);
};

sub get_request_options {
    my $self = shift;
    my(%options) = ();
    if($self->ssl_verify || $self->ssl_ca_file || $self->ssl_key_file || $self->ssl_cert_file){
        $options{tls_ctx} = {
            ca_file   => $self->ssl_ca_file,
            cert_file => $self->ssl_cert_file,
            key_file  => $self->ssl_key_file,
            verify    => $self->ssl_verify,
        };
        if ($self->username && $self->password) {
            $options{headers}{Authorization} = "Basic ".encode_base64($self->username.':'.$self->password);
        }
        elsif($self->token){
            $options{headers}{Authorization} = "Bearer ".$self->token;
        }
    }
    return wantarray ? %options : \%options;
}

sub handle_simple_request {
    my $self = shift;
    my $method = shift;
    my $uri = shift;
    my(%options) =  @_;
    my $body = delete $options{body};

    my($cv, $resourceList);
    my(%access_options) = $self->get_request_options;
    my $return = delete $options{return};
    if($return){
        $cv = AnyEvent->condvar;
    }
    http_request
        $method, $uri,
        body => $body,
        %access_options,
        sub {
            my($body, $headers) = @_;
            if($headers->{Status} < 200 || $headers->{Status} > 400){
                if($options{error}){
                    try {
                        my $message = $self->json->decode($body);
                        $options{error}->($message);
                    } catch ($e) {
                        $options{error}->($body);
                    }
                }
            }else{
                if($options{cb}){
                    my $resourceHash = $self->json->decode($body);
                    $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(%$resourceHash, api_access => $self));
                }
            }
            if($cv){
                $cv->send;
            }
        };

    if($cv){
        $cv->recv;
        return $resourceList;
    }
}

sub handle_streaming_request {
    my $self = shift;
    my $method = shift;
    my $uri = shift;
    my(%form) = $uri->query_form;
    $form{watch} = 'true';
    $form{resourceVersion} = delete $options{resourceVersion} || 0;
    $uri->query_form(%form);
    my(%options) =  @_;
    my $body = delete $options{body};

    my($cv, $resourceList);
    my(%access_options) = $self->get_request_options;

    my $chunk = '';
    http_request
        $method, $uri,
        want_body_handle => 1,
        %access_options,
        body => $body,
        sub {
            my($handle, $headers) = @_;
            if(! $handle){
                if($options{error}){
                    $options{error}->("Failed to connect to kubernetes");
                }
                return;
            }
            $handle->on_read(
                sub {
                    my $buf = $handle->{rbuf};
                    $handle->{rbuf} = '';
                    foreach my $line (split(/\r\n/, $buf)) {

                        # Skip empty lines, or lines containing only hex numbers (length of next blob)
                        unless ($line =~ m/^\s*$/ || $line =~ m/^[0-9a-f]+$/) {
                            $chunk .= $line;
                            my $update;
                            try {
                                $update = $self->json->decode($chunk);
                                use Data::Dumper; print Dumper($update)."\n";
                                $chunk  = '';
                                $options{resourceVersion} = $update->{object}{metadata}{resourceVersion};
                                $options{change}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(%{ $update->{object} }, api_access => $self), $update->{type});
                            }
                            catch($e) {
                                # Ignore this error, probably means we have an incomplete JSON
                                # blob, and well get the rest of it in the next call
                            };
                        }
                    }
                }
            );
            $handle->on_error(
                sub {
                    my(undef, undef, $message) = @_;
                    if($options{error}){
                        $options{error}->($message);
                    }
                    $handle->destroy;
                }
            );
            $handle->on_eof(
                sub {
                    if($options{auto_reconnect}){
                        $self->handle_streaming_request($method, $uri, %options)
                    }
                    else {
                        $options{disconnect}->();
                    }
                }
            );
        };
}

return 42;
