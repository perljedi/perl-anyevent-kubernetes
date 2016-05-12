#!/usr/local/bin/perl
use strict;
use warnings;
use Test::Spec;
use lib qw(..);
use Jasmine::Spy qw(spyOn stopSpying expectSpy getCalls);
use AnyEvent::Kubernetes;
use base qw(Test::Spec);
use vars qw($sut);
use MIME::Base64;

describe "AnyEvent::Kubernetes" => sub {
    before all => sub {
        $sut = AnyEvent::Kubernetes->new;
    };
    describe "create" => sub {
        before each => sub {
            spyOn($sut->api_access, 'handle_simple_request');
            getCalls($sut->api_access, 'handle_simple_request')->reset;
        };
        it "calls handle_simple_request" => sub {
            $sut->create({ kind => 'Pod' });
            expectSpy($sut->api_access, 'handle_simple_request')->toHaveBeenCalled->once;
        };
        it "makes a post request" => sub {
            $sut->create({ kind => 'Pod' });
            is(getCalls($sut->api_access, 'handle_simple_request')->mostRecent->[0], 'POST');
        };
        it "uses the 'kind' from the resource object in the url" => sub {
            $sut->create({ kind => 'Pod' });
            like(getCalls($sut->api_access, 'handle_simple_request')->mostRecent->[1], qr/pods$/);
        };
        it "can read object from a json file if passed in" => sub {
            $sut->create('t/test_json_object.json');
            like(getCalls($sut->api_access, 'handle_simple_request')->mostRecent->[1], qr/services$/);
        };
        it "can read object from a yaml file if passed in" => sub {
            $sut->create('t/test_yaml_object.yaml');
            like(getCalls($sut->api_access, 'handle_simple_request')->mostRecent->[1], qr/replicationcontrollers/);
        };
    };
    describe "list_namespaces" => sub {
        it "calls _fetch_resource with 'namespaces'" => sub {
            spyOn($sut, '_fetch_resource');
            getCalls($sut, '_fetch_resource')->reset;
            $sut->list_namespaces;
            expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
            is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'namespaces');
        }
    };
    describe "get_namespace" => sub {
        it "calls _fetch_resource with 'namespaces/NAME'" => sub {
            spyOn($sut, '_fetch_resource');
            getCalls($sut, '_fetch_resource')->reset;
            $sut->get_namespace('default');
            expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
            is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'namespaces/default');
        }
    };
    describe "list_nodes" => sub {
        it "calls _fetch_resource with 'nodes'" => sub {
            spyOn($sut, '_fetch_resource');
            getCalls($sut, '_fetch_resource')->reset;
            $sut->list_nodes;
            expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
            is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'nodes');
        }
    };
    describe "get_node" => sub {
        it "calls _fetch_resource with 'nodes/NAME'" => sub {
            spyOn($sut, '_fetch_resource');
            getCalls($sut, '_fetch_resource')->reset;
            $sut->get_node('mynode');
            expectSpy($sut, '_fetch_resource')->toHaveBeenCalled->once;
            is(getCalls($sut, '_fetch_resource')->mostRecent->[0], 'nodes/mynode');
        }
    };
};

runtests;
