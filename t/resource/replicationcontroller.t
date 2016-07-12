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

describe "AnyEvent::Kubernetes::Resource::ReplicationController" => sub {
    before all => sub {
        my $kube = AnyEvent::Kubernetes->new;
        $sut = AnyEvent::Kubernetes::ResourceFactory->get_resource(
            kind => 'ReplicationController',
            metadata => {
                selfLink => '/api/v1/namespaces/default/replicationcontrollers/my_app_rc',
            },
            spec => {
                selector => {
                    app => 'my_app',
                },
                replicas=>1,
            },
            api_access => $kube->api_access
        );
    };
    xdescribe "scale" => sub {
        before all => sub {
            spyOn($sut, 'update');
            spyOn($sut, 'get_pods');
        };
        before each => sub {
            getCalls($sut, 'update')->reset;
            getCalls($sut, 'get_pods')->reset;
        };
        it "sets the replica count" => sub {
            $sut->scale(2);
            is($sut->spec->{replicas}, 2);
        };
        it "calls update" => sub {
            $sut->scale(2);
            expectSpy($sut, 'update')->toHaveBeenCalled->once;
        };
        it "calls get_pods when the update succeeds" => sub {
            spyOn($sut, 'update')->andCallFake(sub {
                my(%options) = @_;
                $options{onSuccess}->();
            });
            $sut->scale(3);
            expectSpy($sut, 'get_pods')->toHaveBeenCalled->once;
        };
        it "calls the supplied callback if the number of pods matches the requested replica count" => sub {
            my $called = 0;
            my $changeCallback;
            $sut->spec->{replicas} = 1;
            spyOn($sut, 'update')->andCallFake(sub {
                my(%options) = @_;
                $options{onSuccess}->();
            });
            spyOn($sut, 'get_pods')->andCallFake(sub {
                my(%options) = @_;
                $changeCallback = $options{onChange};
                return sub {};
            });
            $sut->scale(2, onSuccess=>sub { $called = 1 });
            $changeCallback->(stub(is_ready => 1, metadata=>{name=>'myPod'}), 'ADDED');
            $changeCallback->(stub(is_ready => 1, metadata=>{name=>'otherPod'}), 'ADDED');
            ok($called);
        };
        it "doesn't call the callback on a scale down until atleast one delete has been seen" => sub {
            my $called = 0;
            my $changeCallback;
            $sut->spec->{replicas} = 3;
            spyOn($sut, 'update')->andCallFake(sub {
                my(%options) = @_;
                $options{onSuccess}->();
            });
            spyOn($sut, 'get_pods')->andCallFake(sub {
                my(%options) = @_;
                $changeCallback = $options{onChange};
                return sub {};
            });
            $sut->scale(2, onSuccess=>sub { $called = 1 });
            $changeCallback->(stub(is_ready => 1, metadata=>{name=>'myPod'}), 'ADDED');
            $changeCallback->(stub(is_ready => 1, metadata=>{name=>'otherPod'}), 'ADDED');
            $changeCallback->(stub(is_ready => 1, metadata=>{name=>'thirdPod'}), 'ADDED');
            ok(!$called);
            $changeCallback->(stub(is_ready => 0, metadata=>{name=>'otherPod'}), 'DELETED');
            ok($called);
        };
        after all => sub {
            stopSpying($sut);
        };
    };
    describe "rolling_update" => sub {
        before all => sub {
            spyOn($sut->api_access, 'handle_simple_request');
        };
        before each => sub {
            $sut->metadata->{creationTimestamp} = "sometime";
            $sut->metadata->{uid} = "something";
            $sut->spec->{securityContext} = { some => "stuff" };
            $sut->spec->{replicas} = 2;
            $sut->spec->{selector}{deployment} = "thefirstone";
            getCalls($sut->api_access, 'handle_simple_request')->reset;
        };
        it "updates it's existing pods with a deployment selector if one is not already present" => sub {
            my $pod = mock();
            $pod->stubs('metadata' => {labels=>{}});
            my $expectation = $pod->expects('update');
            delete $sut->spec->{selector}{deployment};
            spyOn($sut, 'update');
            spyOn($sut, 'get_pods')->andCallFake(sub {
                my(%opts) = @_;
                $opts{onSuccess}->(stub(all=>[$pod]));
            });
            $sut->rolling_update;
            ok($expectation->verify);
        };
        it "updates itself with a deployment selector if one is not already present" => sub {
            delete $sut->spec->{selector}{deployment};
            spyOn($sut, 'update');
            spyOn($sut, 'get_pods')->andCallFake(sub {
                my(%opts) = @_;
                $opts{onSuccess}->(stub(all=>[]));
            });
            $sut->rolling_update;
            expectSpy($sut, 'update')->toHaveBeenCalled->once;
            ok($sut->spec->{selector}{deployment});
        };
        it "creates a new replication controller with a deployment handle" => sub {
            $sut->rolling_update;
            expectSpy($sut->api_access, 'handle_simple_request')->toHaveBeenCalled->once;
            my($method, $uri, %parameters) = @{ getCalls($sut->api_access, 'handle_simple_request')->mostRecent };
            is($method, 'POST');
            my($new_rc) = $sut->json->decode($parameters{body});
            ok(exists($new_rc->{spec}{selector}{deployment}));
        };
        after each => sub {
            getCalls($sut, 'get_pods')->reset;
            getCalls($sut, 'update')->reset;
        };
    };
};

runtests;
