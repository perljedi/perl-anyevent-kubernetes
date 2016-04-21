package AnyEvent::Kubernetes::Role::APIAccess;
use strict;
use warnings;

use Moose::Role;

has url => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => 'http://localhost:8080',
);

has api_version => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has base_path => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	lazy     => 1,
	builder  => '_create_default_base_path'
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

has ua => (
	is       => 'ro',
	isa      => 'LWP::UserAgent',
	required => 1,
	builder  => '_build_lwp_agent',
    lazy     => 1,
);

has token => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has 'json' => (
    is       => 'ro',
    isa      => JSON::MaybeXS::JSON,
    required => 1,
    lazy     => 1,
    builder  => '_build_json',
);

has 'ssl_cert_file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'ssl_key_file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'ssl_ca_file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'ssl_verify' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);


sub _get_request_options {

}

return 42;
