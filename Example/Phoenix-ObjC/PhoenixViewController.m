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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Opens connection to Phoenix
    _phoenix = [[Phoenix alloc] initWithURL:[NSURL URLWithString:@"ws://10.0.0.7:4000/ws"]];
    [_phoenix setDelegate:self];
    [_phoenix open];
    
    // Creates, listens on, and joins channel
    _channel = [[PhoenixChannel alloc] initWithName:@"channel" topic:@"incoming" message:nil withPhoenix:_phoenix];
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

- (void)phoenix:(Phoenix *)phoenix sentEvent:(NSString *)event onTopic:(NSString *)topic onChannel:(NSString *)channel withMessage:(id)message {
    NSLog(@"Phoenix sent event(%@) on topic(%@) on channel(%@) with message - %@", event, topic, channel, message);
}


#pragma mark - Private

- (void)testSend {
    if (_count > 5) {
        [_timer invalidate];
        [_channel leave];
        return;
    }
    
    _count++;
    [_channel sendEvent:@"event" message:@{ @"value" : @"heyyyyy" }];
}

@end

