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
    describe "handle_simple_request" => sub {
        my($response_body, $response_headers);
        before all => sub {
            $sut = AnyEvent::Kubernetes::APIAccess->new;
        };
        before each => sub {
            $response_headers = {Status=>200};
            # Slightly odd.. we have to spy on the is the APIAccess namespace because
            # it is an imported function.
            spyOn('AnyEvent::Kubernetes::APIAccess', 'http_request')->andCallFake(sub {
                my $cb = pop @_;
                $cb->($response_body, $response_headers);
            });
            getCalls('AnyEvent::Kubernetes::APIAccess', 'http_request')->reset;
        };
        it "makes an http request" => sub {
            $response_body = '{"kind":"PodList", "items":[], "metadata":{}}';
            $sut->handle_simple_request(GET => '/api/v1/namespaces', return => 1);
            expectSpy('AnyEvent::Kubernetes::APIAccess', 'http_request')->toHaveBeenCalled->once;
        };
        it "calls there error callback on error" => sub {
            $response_headers = {Status => 500};
            $response_body = '{"message":"fail"}';
            my $called = 0;
            $sut->handle_simple_request(GET => '/api/v1/namespaces', return => 1, error=> sub { $called=1; });
            expectSpy('AnyEvent::Kubernetes::APIAccess', 'http_request')->toHaveBeenCalled->once;
            ok($called);
        };
        it "calls the cb with request object on success" => sub {
            my $object;
            $response_body = '{"kind":"PodList", "items":[], "metadata":{}}';
            $sut->handle_simple_request(GET => '/api/v1/namespaces', return => 1, cb=> sub { $object = shift; });
            isa_ok($object, 'AnyEvent::Kubernetes::ResourceList');
        };
    };
};

runtests;
