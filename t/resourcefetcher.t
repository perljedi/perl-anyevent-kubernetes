#!/usr/local/bin/perl
use strict;
use warnings;
use Test::Spec;
use lib qw(..);
use AnyEvent::Kubernetes;
use Jasmine::Spy qw(spyOn stopSpying expectSpy getCalls);
use base qw(Test::Spec);
use vars qw($sut);

describe "AnyEvent::Kubernetes::Role::ResourceFetcher" => sub {
    before all => sub {
        $sut = AnyEvent::Kubernetes->new;
        spyOn($sut->api_access, 'handle_simple_request');
        spyOn($sut->api_access, 'handle_streaming_request');
    };
    before each => sub {
        getCalls($sut->api_access, 'handle_simple_request')->reset;
        getCalls($sut->api_access, 'handle_streaming_request')->reset;
    };
    it "calls handle_simple_request if not passed an change callback" => sub {
        $sut->_fetch_resource('pods');
        expectSpy($sut->api_access, 'handle_simple_request')->toHaveBeenCalled->once;
    };
    it "calls handle_streaming_request if passed an change callback" => sub {
        $sut->_fetch_resource('pods', change=> sub {});
        expectSpy($sut->api_access, 'handle_streaming_request')->toHaveBeenCalled->once;
    };
    it "builds the request url correctly" => sub {
        $sut->_fetch_resource('pods', );
        is(getCalls($sut->api_access, 'handle_simple_request')->mostRecent->[1], "http://localhost:8080/api/v1/api/v1/pods");
    };
    it "builds the labelSelector if supplied" => sub {
        $sut->_fetch_resource('pods', labels=>{name=>'dave'});
        cmp_deeply({
            getCalls($sut->api_access, 'handle_simple_request')
                ->mostRecent->[1]->query_form },
            {labelSelector => 'name=dave'});
    };
    it "builds the fieldSelector if supplied" => sub {
        $sut->_fetch_resource('pods', fields=>{name=>'dave'});
        cmp_deeply({
            getCalls($sut->api_access, 'handle_simple_request')
                ->mostRecent->[1]->query_form },
            {fieldSelector => 'name=dave'});
    };
};

runtests;
