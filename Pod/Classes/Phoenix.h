//
//  Phoenix.h
//  Pods
//
//  Created by Josh Holtz on 12/5/14.
//
//

#import <Foundation/Foundation.h>

@class PhoenixChannel;
@protocol PhoenixDelegate;

@interface Phoenix : NSObject

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, assign) id<PhoenixDelegate> delegate;

- (instancetype)initWithURL:(NSURL*)url;

- (void)open;
- (void)close;

@end

@protocol PhoenixDelegate <NSObject>

- (void)phoenixOpened:(Phoenix*)phoenix;
- (void)phoenixClosed:(Phoenix*)phoenix;

- (void)phoenix:(Phoenix*)phoenix sentEvent:(NSString*)event onTopic:(NSString*)topic onChannel:(NSString*)channel withMessage:(id)message;

- (void)phoenix:(Phoenix*)phoenix failedWithError:(NSError*)error;

@end

@interface PhoenixChannel : NSObject

typedef void(^HandleEventBlock)(id message);

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *topic;
@property (nonatomic, strong, readonly) NSDictionary *message;
@property (nonatomic, strong, readonly) Phoenix *phoenix;

- (instancetype)initWithName:(NSString*)name topic:(NSString*)topic message:(NSDictionary*)message withPhoenix:(Phoenix*)phoenix;

- (BOOL)join;
- (BOOL)leave;

- (void)sendEvent:(NSString*)event message:(id)message;

- (void)on:(NSString*)event handleEventBlock:(HandleEventBlock)handleEventBlock;

@end