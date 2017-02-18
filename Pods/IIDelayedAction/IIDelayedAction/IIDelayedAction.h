//
//  IIDelayedAction.h
//
//  Created by Tom Adriaenssen on 01/02/14.
//  Copyright (c) 2014 Tom Adriaenssen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IIDelayedAction : NSObject

@property (nonatomic, assign, readonly) NSTimeInterval delay;
@property (nonatomic, assign, readonly) BOOL hasAction;
@property (nonatomic, assign) BOOL onMainThread;

- (void)action:(void(^)(void))action;

+ (IIDelayedAction*)delayedActionWithDelay:(NSTimeInterval)delay;
+ (IIDelayedAction*)delayedAction:(void(^)(void))action withDelay:(NSTimeInterval)delay;


@end
