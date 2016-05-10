#!/usr/local/bin/perl
use strict;
use warnings;
use Test::Spec;
use lib qw(..);
use Jasmine::Spy qw(spyOn stopSpying expectSpy getCalls);
use base qw(Test::Spec);
use vars qw($sut);
use MIME::Base64;

describe "AnyEvent::Kubernetes::Resource::Namespace" => sub {
    it "compiles" => sub {
        use_ok('AnyEvent::Kubernetes::APIAccess');
    };
    describe "get_request_options" => sub {
        it "should include an authorization bearer header for token based auth" => sub {
            my $api = AnyEvent::Kubernetes::APIAccess->new(token=>'./t/my_token.dat');
            my $options = $api->get_request_options;
            cmp_deeply($options, superhashof({headers=>superhashof({Authorization => re(qr/^Bearer /)})}));
        };
        it "should include an authorization basic header for password based auth" => sub {
            my $api = AnyEvent::Kubernetes::APIAccess->new(username=>'dave', password=>'threve');
            my $options = $api->get_request_options;
            cmp_deeply($options, superhashof({headers=>superhashof({Authorization => "Basic ".encode_base64("dave:threve")})}));
        };
        it "should include a tls context for cert base authentication" => sub {
            my $api = AnyEvent::Kubernetes::APIAccess->new(
                ssl_verify    => 1,
                ssl_ca_file   => '/some/path/to/ca',
                ssl_cert_file => '/some/path/to/cert',
                ssl_key_file  => '/some/path/to/key',
            );
            my $options = $api->get_request_options;
            cmp_deeply($options, superhashof({tls_ctx => ignore}));
        };
    };
};

runtests;
