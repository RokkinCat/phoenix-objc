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
    if (channel == nil || channel.name.length == 0) return NO;
    
    // Makes sure channel isn't already joined
    if (_channels[channel.name] != nil) return NO;
    _channels[channel.name] = channel;
    
    // Joins channel
    [self send:channel.name topic:channel.topic event:@"join" message:nil];
    
    return YES;
}

- (BOOL)leaveChannel:(PhoenixChannel*)channel {
    // Makes sure channel is valid
    if (channel == nil || channel.name.length == 0) return NO;
    
    // Makes sure channel is already joined
    if (_channels[channel.name] == nil) return NO;
    [_channels removeObjectForKey:channel.name];
    
    // Leaves channel
    [self send:channel.name topic:channel.topic event:@"leave" message:nil];
    
    return YES;
}

#pragma mark - Private

- (void)sendHeartbeat {
    [self send:@"phoenix" topic:@"conn" event:@"heartbeat" message:@{}];
}

#pragma mark - Helpers

- (void)send:(NSString*)channel topic:(NSString*)topic event:(NSString*)event message:(id)message {
    
    NSDictionary *payload = @{
                              @"channel": channel,
                              @"topic": topic,
                              @"event": event,
                              @"message": message ?: [NSNull null]
                              };
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    __block NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [_queue addOperationWithBlock:^{
        [_webSocket send:string];
        
        if ([_delegate respondsToSelector:@selector(phoenix:sentEvent:onTopic:onChannel:withMessage:)]) {
            [_delegate phoenix:self sentEvent:event onTopic:topic onChannel:channel withMessage:message];
        }
    }];
    
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    PhoenixChannel *channel = _channels[resp[@"channel"]];
    [channel handleEvent:resp[@"event"] withMessage:resp[@"message"]];
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

- (instancetype)initWithName:(NSString*)name topic:(NSString*)topic message:(NSDictionary*)message withPhoenix:(Phoenix*)phoenix {
    self = [super init];
    if (self) {
        _name = name;
        _topic = topic;
        _message = message;
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

- (void)sendEvent:(NSString*)event message:(id)message {
    [_phoenix send:_name topic:_topic event:event message:message];
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
