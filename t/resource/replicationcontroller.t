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
        api_access => $kube->api_access);
    };
    describe "scale" => sub {
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
                $options{cb}->();
            });
            $sut->scale(3);
            expectSpy($sut, 'get_pods')->toHaveBeenCalled->once;
        };
        it "calls the supplied callback if the number of pods matches the requested replica count" => sub {
            my $called = 0;
            spyOn($sut, 'update')->andCallFake(sub {
                my(%options) = @_;
                $options{cb}->();
            });
            spyOn($sut, 'get_pods')->andCallFake(sub {
                my(%options) = @_;
                $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(
                    kind => "PodList",
                    items => [
                        {
                            metadata=>{},
                            status=>{},
                            spec=>{}
                        }
                    ],
                    metadata=>{},
                    apiVersion => 'v1',
                    api_access => $sut->api_access,
                ));
            });
            $sut->scale(1, cb=>sub { $called = 1 });
            ok($called);

        };
        it "schedules a second call to get_pods if the number is not correct yet" => sub {
            my $called = 0;
            my $itteration = 1;
            spyOn($sut, 'update')->andCallFake(sub {
                my(%options) = @_;
                $options{cb}->();
            });
            spyOn($sut, 'get_pods')->andCallFake(sub {
                my(%options) = @_;
                if($itteration == 1){
                    $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(
                        kind => "PodList",
                        items => [
                            {
                                metadata=>{},
                                status=>{},
                                spec=>{}
                            }
                        ],
                        metadata=>{},
                        apiVersion => 'v1',
                        api_access => $sut->api_access,
                    ));
                    $itteration++;
                }else{
                    $options{cb}->(AnyEvent::Kubernetes::ResourceFactory->get_resource(
                        kind => "PodList",
                        items => [
                            {
                                metadata=>{},
                                status=>{},
                                spec=>{}
                            },
                            {
                                metadata=>{},
                                status=>{},
                                spec=>{}
                            }
                        ],
                        metadata=>{},
                        apiVersion => 'v1',
                        api_access => $sut->api_access,
                    ));
                }
            });
            my $cv = AnyEvent->condvar;
            $sut->scale(2, update_interval=> 1, cb=>sub { $called = 1; $cv->send; });
            $cv->recv;
            expectSpy($sut, 'get_pods')->toHaveBeenCalled->exactly(2);
            ok($called);

        };
    };
};

runtests;
