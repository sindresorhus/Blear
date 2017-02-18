#NZAssetsLibrary

NZAssetsLibrary is a ALAssetsLibrary extension.
This class save, delete and load images from specific album or device folder.

[![Build Status](https://api.travis-ci.org/NZN/NZAssetsLibrary.png)](https://api.travis-ci.org/NZN/NZAssetsLibrary.png)

## Requirements

NZAssetsLibrary works on iOS 5.0+ and is compatible with ARC projects. It depends on the following Apple frameworks, which should already be included with most Xcode templates:

* AssetsLibrary.framework
* Foundation.framework

You will need LLVM 3.0 or later in order to build NZAssetsLibrary.

To build the sample is necessary iOS 6+ (sample project use `UICollectionViewController` class).
The sample project uses [AGPhotoBrowser](https://github.com/andreagiavatto/AGPhotoBrowser).

## Adding NZAssetsLibrary to your project

### Cocoapods

[CocoaPods](http://cocoapods.org) is the recommended way to add NZAssetsLibrary to your project.

* Add a pod entry for NZAssetsLibrary to your Podfile `pod 'NZAssetsLibrary', :git => 'https://github.com/NZN/NZAssetsLibrary'`
* Install the pod(s) by running `pod install`.

### Source files

Alternatively you can directly add source files to your project.

1. Download the [latest code version](https://github.com/NZN/NZAssetsLibrary/archive/master.zip) or add the repository as a git submodule to your git-tracked project.
2. Open your project in Xcode, then drag and drop all files at `NZAssetsLibrary` folder onto your project (use the "Product Navigator view"). Make sure to select Copy items when asked if you extracted the code archive outside of your project.

## Usage

* Save image

```objective-c
#import "NZAssetsLibrary.h"
...

UIImage *image = [UIImage imageNamed:@"image.png"];

// NZAssetsLibrary unique instance
NZAssetsLibrary *assetsLibrary = [NZAssetsLibrary defaultAssetsLibrary];

// save image at album
[assetsLibrary saveImage:image toAlbum:@"Album name" withCompletion:^(NSError *error) {
    if (error) {
        NSLog(@"Failed to save image.");
        return;
    }
    
    NSLog(@"Image saved successfully.");
}];

// save image at device document directory
[assetsLibrary saveJPGImageAtDocumentDirectory:image];
[assetsLibrary savePNGImageAtDocumentDirectory:image];
```

* Load images

```objective-c
#import "NZAssetsLibrary.h"
#import "NZAssetImageFile.h"
...

// NZAssetsLibrary unique instance
NZAssetsLibrary *assetsLibrary = [NZAssetsLibrary defaultAssetsLibrary];

// load images from album
[assetsLibrary loadImagesFromAlbum:@"My Album" withCallback:^(NSArray<NZAssetImageFile> *assets, NSError *error) {
    if (error) {
        NSLog(@"Could not load images.");
        return;
    }
    
    NSLog(@"Loaded successfully.");
}];

// load images from device document directory
NSArray<NZAssetImageFile> *array = [assetsLibrary loadImagesFromDocumentDirectory];
```

* Delete file

```objective-c
#import "NZAssetsLibrary.h"
#import "NZAssetFile.h"
...

NZAssetFile *file = ...;

// NZAssetsLibrary unique instance
NZAssetsLibrary *assetsLibrary = [NZAssetsLibrary defaultAssetsLibrary];
[assetsLibrary deleteFile:file];
```

## License

This code is distributed under the terms and conditions of the [MIT license](LICENSE).

## Change-log

A brief summary of each NZAssetsLibrary release can be found on the [wiki](https://github.com/NZN/NZAssetsLibrary/wiki/Change-log).