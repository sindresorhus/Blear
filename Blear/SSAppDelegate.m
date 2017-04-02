//
//  SSAppDelegate.m
//  Blear
//
//  Created by Sindre Sorhus on 9/15/13.
//  Copyright (c) 2017 Sindre Sorhus. All rights reserved.
//

#import "SSAppDelegate.h"
#import "SSViewController.h"

@implementation SSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

	SSViewController *rootViewController = [[SSViewController alloc] initWithNibName:nil bundle:nil];
	self.window.rootViewController = rootViewController;

	[self.window makeKeyAndVisible];

	// First launch
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"firstTime"] == NULL) {
		[[NSUserDefaults standardUserDefaults] setValue:@"not" forKey:@"firstTime"];

        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Tip"
                                                                        message:@"Shake the device to get a random image."
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* coolAction = [UIAlertAction actionWithTitle:@"Cool"
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil];
        
        [alert addAction:coolAction];
        
        [rootViewController presentViewController:alert animated:YES completion:nil];
	}

	return YES;
}

@end
