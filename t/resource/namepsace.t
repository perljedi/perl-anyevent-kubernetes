#!/usr/local/bin/perl
use strict;
use warnings;
use Test::Spec;
use lib qw(..);
use AnyEvent::Kubernetes;
use Jasmine::Spy qw(spyOn stopSpying expectSpy getCalls);
use base qw(Test::Spec);
use vars qw($sut);

describe "AnyEvent::Kubernetes::Resource::Namespace" => sub {
    my($kube);
    before all => sub {
        $kube = AnyEvent::Kubernetes->new(url => "http://172.18.8.101:8080");
        spyOn('AnyEvent::Kubernetes::APIAccess', 'http_request')
            ->andReturn(sub {
                my($callback) = pop @_;
                $callback->('{"kind":"Namespace", "apiVersion":"v1", "metadata":{ "selfLink":"/api/v1/namespaces/default" }}', {Status => 200});
            });
        $sut = $kube->default_namespace;
        spyOn($sut, '_fetch_resource');
    };
    before each => sub {
        getCalls($sut, '_fetch_resource')->reset;
    };
    it "is a namespace object" => sub {
        isa_ok($sut, 'AnyEvent::Kubernetes::Resource::Namespace');
    };
    it "uses _fetch_resource to list pods" => sub {
        $sut->list_pods;
        expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
        is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'pods');
    };
    it "uses _fetch_resource to list replicationcontrollers" => sub {
        $sut->list_rc;
        expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
        is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'replicationcontrollers');
    };
    it "uses _fetch_resource to list services" => sub {
        $sut->list_services;
        expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
        is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'services');
    };
    it "uses _fetch_resource to list events" => sub {
        $sut->list_events;
        expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
        is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'events');
    };
    it "uses _fetch_resource to list endpoints" => sub {
        $sut->list_endpoints;
        expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
        is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'endpoints');
    };

};

runtests;
