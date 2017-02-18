//
//  UIView+UIView_CaptureImage.m
//  Blear
//
//  Created by Sindre Sorhus on 9/15/13.
//  Copyright (c) 2017 Sindre Sorhus. All rights reserved.
//

#import "UIImage+UIViewCapture.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage (UIViewCapture)

- (UIImage *)imageWithView:(UIView *)view {
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return img;
}

@end
