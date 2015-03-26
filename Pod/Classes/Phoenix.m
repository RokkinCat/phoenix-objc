//
//  Phoenix.m
//  Pods
//
//  Created by Josh Holtz on 12/5/14.
//
//

#import "Phoenix.h"

#import <SocketRocket/SRWebSocket.h>

@interface Phoenix()<SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, assign) BOOL isOpen;

@property (nonatomic, strong) NSMutableDictionary *channels;

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *heartbeatTimer;

@end

@interface PhoenixChannel()

@property (nonatomic, strong) NSMutableDictionary *listeners;

- (void)handleEvent:(NSString*)event withMessage:(id)message;

@end

@implementation Phoenix

- (instancetype)initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        _url = url;

        _channels = @{}.mutableCopy;

        _queue = [[NSOperationQueue alloc] init];
        [_queue setSuspended:YES];
    }
    return self;
}

#pragma mark - Public

- (void)open {
    if (_webSocket == nil && _isOpen == NO) {
        _webSocket = [[SRWebSocket alloc] initWithURL:_url];
        [_webSocket setDelegate:self];
        [_webSocket open];
    }
}

- (void)close {
    [_webSocket close];
}

#pragma mark - Private Channels

- (BOOL)joinChannel:(PhoenixChannel*)channel {
    // Makes sure channel is valid
    if (channel == nil || channel.topic.length == 0) return NO;

    // Makes sure channel isn't already joined
    if (_channels[channel.topic] != nil) return NO;
    _channels[channel.topic] = channel;

    // Joins channel
    [self send:channel.topic event:@"join" payload:channel.payload];

    return YES;
}

- (BOOL)leaveChannel:(PhoenixChannel*)channel {
    // Makes sure channel is valid
    if (channel == nil || channel.topic.length == 0) return NO;

    // Makes sure channel is already joined
    if (_channels[channel.topic] == nil) return NO;
    [_channels removeObjectForKey:channel.topic];

    // Leaves channel
    [self send:channel.topic event:@"leave" payload:nil];

    return YES;
}

#pragma mark - Private

- (void)sendHeartbeat {
    [self send:@"phoenix" event:@"heartbeat" payload:@{}];
}

#pragma mark - Helpers

- (void)send:(NSString*)topic event:(NSString*)event payload:(id)payload {

    NSDictionary *message = @{
                              @"topic": topic,
                              @"event": event,
                              @"payload": payload ?: [NSNull null]
                              };

    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
    __block NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [_queue addOperationWithBlock:^{
        [_webSocket send:string];

        if ([_delegate respondsToSelector:@selector(phoenix:sentEvent:onTopic:withPayload:)]) {
            [_delegate phoenix:self sentEvent:event onTopic:topic withPayload:payload];
        }
    }];

}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

    PhoenixChannel *channel = _channels[resp[@"topic"]];
    [channel handleEvent:resp[@"event"] withMessage:resp[@"payload"]];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    _isOpen = YES;
    [_queue setSuspended:NO];

    // Start heartbeat timer
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;
    _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(sendHeartbeat) userInfo:nil repeats:YES];

    if ([_delegate respondsToSelector:@selector(phoenixOpened:)]) {
        [_delegate phoenixOpened:self];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(phoenix:failedWithError:)]) {
        [_delegate phoenix:self failedWithError:error];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    _webSocket = nil;
    _isOpen = NO;
    [_queue setSuspended:YES];

    // Stop heartbeat timer
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;

    if ([_delegate respondsToSelector:@selector(phoenixClosed:)]) {
        [_delegate phoenixClosed:self];
    }
}

@end

@implementation PhoenixChannel

- (instancetype)initWithTopic:(NSString*)topic payload:(NSDictionary*)payload withPhoenix:(Phoenix*)phoenix {
    self = [super init];
    if (self) {
        _topic = topic;
        _payload = payload;
        _phoenix = phoenix;

        _listeners = @{}.mutableCopy;
    }
    return self;
}

#pragma mark - Public

- (BOOL)join {
    return [_phoenix joinChannel:self];
}

- (BOOL)leave {
    return [_phoenix leaveChannel:self];
}

- (void)sendEvent:(NSString*)event payload:(id)payload {
    [_phoenix send:_topic event:event payload:payload];
}

- (void)on:(NSString*)event handleEventBlock:(HandleEventBlock)handleEventBlock {
    _listeners[event] = handleEventBlock;
}

#pragma mark - Private

- (void)handleEvent:(NSString*)event withMessage:(id)message {
    HandleEventBlock block = _listeners[event];
    if (block) {
        block(message);
    }
}

@end
