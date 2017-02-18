//
//  PerformSelectorWithDebounce.m
//
//  Created by David Mojdehi on 9/6/13.
//  Copyright (c) 2013 Mindful Bear Apps. All rights reserved.
//

#import "PerformSelectorWithDebounce.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (PerformSelectorWithDebounce)

const char *kDictionaryOfSelectorsToBlock = "kDictionaryOfSelectorsToBlock";

- (void)performSelector:(SEL)aSelector withDebounceDuration:(NSTimeInterval)duration
{
	// we track which selectors are pending in a dictonary (associated with this object)
	// get it now (or create it if it doesn't exist)
	NSMutableDictionary *blockedSelectors = objc_getAssociatedObject(self, kDictionaryOfSelectorsToBlock);
	if(!blockedSelectors)
	{
		blockedSelectors = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, kDictionaryOfSelectorsToBlock, blockedSelectors, OBJC_ASSOCIATION_RETAIN);
	}
	
	// do we already have a pending call for this selector?
	NSString *aSelectorAsStr = NSStringFromSelector(aSelector);
	NSValue *blockIt = blockedSelectors[aSelectorAsStr];
	if(blockIt)
	{
		// yes; we get here if there's already a call pending
		// so ignore (debounce) this call
	}
	else
	{
		// first, remember to block subsequent calls to it
		blockedSelectors[aSelectorAsStr] = @YES;
		
		// perform it now
		((id (*)(id, SEL))objc_msgSend)(self, aSelector);
		
		// unblock it after the delay
		[self performSelector:@selector(unblockSelectorNamed:) withObject:aSelectorAsStr afterDelay:duration];
		
	}
}

-(void)unblockSelectorNamed:(NSString*)selectorAsString
{
	NSMutableDictionary *blockedSelectors = objc_getAssociatedObject(self, kDictionaryOfSelectorsToBlock);
	
	// we've called the selector; so allow future calls again
	[blockedSelectors removeObjectForKey:selectorAsString];
}

@end
