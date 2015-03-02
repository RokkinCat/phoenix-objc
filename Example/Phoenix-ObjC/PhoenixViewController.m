//
//  PhoenixViewController.m
//  Phoenix-ObjC
//
//  Created by rokkincat on 12/05/2014.
//  Copyright (c) 2014 rokkincat. All rights reserved.
//

#import "PhoenixViewController.h"

#import <Phoenix-ObjC/Phoenix-ObjC.h>

@interface PhoenixViewController ()<PhoenixDelegate>

@property (nonatomic, strong) Phoenix *phoenix;
@property (nonatomic, strong) PhoenixChannel *channel;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger count;

@end

@implementation PhoenixViewController

//30s
//sendHeartbeat: ->
//@send(topic: "phoenix:conn", event: "heartbeat", payload: {})

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4000/ws"];
    
    // Opens connection to Phoenix
    _phoenix = [[Phoenix alloc] initWithURL:url];
    [_phoenix setDelegate:self];
    [_phoenix open];
    
    // Creates, listens on, and joins channel
    _channel = [[PhoenixChannel alloc] initWithTopic:@"channel:incoming" payload:nil withPhoenix:_phoenix];
    [_channel on:@"response:event" handleEventBlock:^(id message) {
        NSLog(@"Message - %@", message);
    }];
    [_channel join];
    
    _count = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(testSend) userInfo:nil repeats:YES];
}

#pragma mark - PhoenixDelegate

- (void)phoenixOpened:(Phoenix *)phoenix {
    NSLog(@"Phoenix opened");
}

- (void)phoenixClosed:(Phoenix *)phoenix {
    NSLog(@"Phoenix closed");
}

- (void)phoenix:(Phoenix *)phoenix failedWithError:(NSError *)error {
    NSLog(@"Phoenix failed with error - %@", error);
}

- (void)phoenix:(Phoenix *)phoenix sentEvent:(NSString *)event onTopic:(NSString *)topic withPayload:(id)payload {
    NSLog(@"Phoenix sent event(%@) on topic(%@) with payload - %@", event, topic, payload);
}


#pragma mark - Private

- (void)testSend {
    if (_count > 5) {
        [_timer invalidate];
        [_channel leave];
        return;
    }
    
    _count++;
    [_channel sendEvent:@"response:event" payload:@{ @"value" : @"heyyyyy" }];
}

@end

