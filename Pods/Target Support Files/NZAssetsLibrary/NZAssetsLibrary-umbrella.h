#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NZAssetFile.h"
#import "NZAssetImageFile.h"
#import "NZAssetsLibrary.h"

FOUNDATION_EXPORT double NZAssetsLibraryVersionNumber;
FOUNDATION_EXPORT const unsigned char NZAssetsLibraryVersionString[];

