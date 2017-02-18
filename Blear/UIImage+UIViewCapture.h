//
//  UIView+UIView_CaptureImage.h
//  Blear
//
//  Created by Sindre Sorhus on 9/15/13.
//  Copyright (c) 2017 Sindre Sorhus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (UIViewCapture)

- (UIImage *)imageWithView:(UIView *)view;

@end
