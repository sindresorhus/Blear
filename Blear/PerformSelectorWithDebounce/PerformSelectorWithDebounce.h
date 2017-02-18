//
//  PerformSelectorWithDebounce.h
//
//  Created by David Mojdehi on 9/6/13.
//  Copyright (c) 2013 Mindful Bear Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PerformSelectorWithDebounce)
- (void)performSelector:(SEL)aSelector withDebounceDuration:(NSTimeInterval)duration;
@end
