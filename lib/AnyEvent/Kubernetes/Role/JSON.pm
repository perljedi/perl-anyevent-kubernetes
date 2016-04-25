package AnyEvent::Kubernetes::Role::JSON;
use strict;
use warnings;

use Moose::Role;
use Moose::Util::TypeConstraints qw(duck_type);

use JSON::MaybeXS;

has 'json' => (
    is       => 'ro',
    isa      => duck_type([qw(encode decode)]),
    required => 1,
    lazy     => 1,
    builder  => '_build_json',
);

sub _build_json {
    return JSON->new->allow_blessed(1)->convert_blessed(1);
}

return 42;
