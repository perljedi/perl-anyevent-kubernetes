#!/usr/local/bin/perl
use strict;
use warnings;
use Test::Spec;
use lib qw(..);
use AnyEvent::Kubernetes;
use AnyEvent::Kubernetes::ResourceFactory;
use Jasmine::Spy qw(spyOn stopSpying expectSpy getCalls);
use base qw(Test::Spec);
use vars qw($sut);

describe "AnyEvent::Kubernetes::Resource" => sub {
    before all => sub {
        my $kube = AnyEvent::Kubernetes->new;
        $sut = AnyEvent::Kubernetes::ResourceFactory->get_resource(
            kind => 'Pod',
            metadata => {
                selfLink => '/api/v1/namespaces/default/pods/mypod',
            },
            spec => {

            },
            status => {

            },
            api_access => $kube->api_access
        );
    };
    describe "refresh" => sub {
        before all => sub {
            spyOn($sut, '_fetch_resource');
        };
        before each => sub {
            getCalls($sut, '_fetch_resource')->reset;
        };
        it "calls _fetch_resource" => sub {
            $sut->refresh;
            expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
        };
        it "calls the supplied callback on success" => sub {
            spyOn($sut, '_fetch_resource')->andCallFake(sub {
                my($resource, %options) = @_;
                $options{onSuccess}->($sut);
            });
            my $called = 0;
            $sut->refresh(onSuccess => sub {
                $called = 1;
            });
            ok($called);
        };
        it "updates its fields with new results" => sub {
            spyOn($sut, '_fetch_resource')->andCallFake(sub {
                my($resource, %options) = @_;
                $options{onSuccess}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(
                    kind => 'Pod',
                    metadata => {
                        selfLink => '/api/v1/namespaces/default/pods/mypod',
                    },
                    spec => {

                    },
                    status => {
                        updated => 1
                    },
                    api_access => $sut->api_access
                ));
            });
            $sut->refresh(onSuccess => sub { });
            is($sut->status->{updated}, 1);
        };
    };
    describe "delete" => sub {
        before all => sub {
            spyOn($sut->api_access, 'handle_simple_request');
        };
        before each => sub {
            getCalls($sut->api_access, 'handle_simple_request')->reset;
        };
        it "makes a delete request" => sub {
            $sut->delete;
            expectSpy($sut->api_access, 'handle_simple_request')->toHaveBeenCalled->once;
            is(getCalls($sut->api_access, 'handle_simple_request')->mostRecent->[0], 'DELETE');
        };
    };
};

runtests;
