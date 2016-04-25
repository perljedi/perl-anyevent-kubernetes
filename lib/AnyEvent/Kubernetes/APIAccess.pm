package AnyEvent::Kubernetes::APIAccess;
use strict;
use warnings;

use Moose;

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

return 42;
