//
//  NZAssetImageFile.m
//  NZAssetsLibrary
//
//  Created by Bruno Furtado on 12/12/13.
//  Copyright (c) 2013 No Zebra Network. All rights reserved.
//

#import "NZAssetImageFile.h"

@implementation NZAssetImageFile

@synthesize title;
@synthesize description;
@synthesize image;

- (id)initWithPath:(NSString *)aPath image:(UIImage *)aImage
{
    self = [super init];
    
    if (self) {
        [self setPath:aPath];
        [self setImage:aImage];
    }
    
    return self;
}

@end