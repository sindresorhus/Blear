//
//  NZAssetsLibrary.m
//  NZAssetsLibrary
//
//  Created by Bruno Furtado on 12/12/13.
//  Copyright (c) 2013 No Zebra Network. All rights reserved.
//

#import "NZAssetsLibrary.h"

@interface NZAssetsLibrary ()

- (void)addAssetURL:(NSURL *)assetURL
            toAlbum:(NSString *)albumName
     withCompletion:(SaveImageCompletion)completion;

- (NSString *)imagePathWithExtension:(NSString *)extension;

- (NSString *)imagesDirectory;

- (NSString *)jpgPath;

- (NSString *)pngPath;

@end



@implementation NZAssetsLibrary

#pragma mark -
#pragma mark - Public class methods

+ (NZAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static NZAssetsLibrary *library = nil;
    
    dispatch_once(&pred, ^{
        library = [[self alloc] init];
    });
    
    return library;
}

#pragma mark -
#pragma mark - Public instance methods

- (void)deleteFile:(NZAssetFile *)file
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager isDeletableFileAtPath:file.path]) {
        NSError *error;
        [fileManager removeItemAtPath:file.path error:&error];
        
#ifdef NZDEBUG
        if (error) {
            NSLog(@"%s Cannot delete file at path: %@", __PRETTY_FUNCTION__, file.path);
        } else {
            NSLog(@"%s File deleted: %@", __PRETTY_FUNCTION__, file.path);
        }
#endif
    }
}

- (void)loadImagesFromAlbum:(NSString *)albumName withCallback:(LoadImagesCallback)callback
{
    __block NSMutableArray<NZAssetImageFile> *items = [@[] mutableCopy];
    
    [self enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
            
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result) {
                    NZAssetImageFile *file = [[NZAssetImageFile alloc] init];
                    
                    ALAssetRepresentation *defaultRep = [result defaultRepresentation];
                    
                    file.image = [UIImage imageWithCGImage:[defaultRep fullScreenImage]
                                                     scale:[defaultRep scale]
                                               orientation:0];
                    
                    file.path = [[result.defaultRepresentation url] absoluteString];
                    
                    [items addObject:file];
                }
                
                callback(items, nil);
                
                return;
            }];
        }
    } failureBlock:^(NSError *error) {
        callback(nil, error);
    }];
}

- (NSArray<NZAssetImageFile> *)loadImagesFromDocumentDirectory
{
    NSError *error;
    NSString *imagesDirectory = [self imagesDirectory];
    
    NSArray *contents = [[NSFileManager defaultManager]
                         contentsOfDirectoryAtPath:imagesDirectory error:&error];
    
    if (error) {
#ifdef NZDEBUG
        NSLog(@"%s Unable to list files in directory", __PRETTY_FUNCTION__);
#endif
        
        return nil;
    }
    
    NSMutableArray<NZAssetImageFile> *items = (NSMutableArray <NZAssetImageFile> *) [[NSMutableArray alloc] init];
    
    for (NSString *fileName in contents) {
        NSString *filePath = [imagesDirectory stringByAppendingPathComponent:fileName];
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        
        if (!imageData) {
#ifdef NZDEBUG
            NSLog(@"%s Image cannot be loaded: %@", __PRETTY_FUNCTION__, filePath);
#endif
            continue;
        }
        
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        NZAssetImageFile *file = [[NZAssetImageFile alloc] initWithPath:filePath image:image];
        [items addObject:file];
    }
    
    return items;
}

- (void)saveImage:(UIImage *)image toAlbum:(NSString *)albumName withCompletion:(SaveImageCompletion)completion
{
    [self writeImageToSavedPhotosAlbum:[image CGImage]
                           orientation:(ALAssetOrientation)image.imageOrientation
                       completionBlock:^(NSURL *assetURL, NSError *error) {
                           if (error) {
                               completion(error);
                               return;
                           }
                           
                           [self addAssetURL:assetURL
                                     toAlbum:albumName
                              withCompletion:completion];
                       }];
}

- (void)saveJPGImageAtDocumentDirectory:(UIImage *)image
{
    NSString *jpgPath = [self jpgPath];
    
    if (!jpgPath) {
#ifdef NZDEBUG
        NSLog(@"%s Image cannot be saved. File path nil.", __PRETTY_FUNCTION__);
#endif
        
        return;
    }
    
    NSData *data = UIImageJPEGRepresentation(image, 1);
    [data writeToFile:jpgPath atomically:YES];
}

- (void)savePNGImageAtDocumentDirectory:(UIImage *)image
{
    NSString *pngPath = [self pngPath];
    
    if (!pngPath) {
#ifdef NZDEBUG
        NSLog(@"%s Image cannot be saved. File path nil.", __PRETTY_FUNCTION__);
#endif
        
        return;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    [data writeToFile:pngPath atomically:YES];
}

#pragma mark -
#pragma mark - Private methods

- (void)addAssetURL:(NSURL *)assetURL toAlbum:(NSString *)albumName withCompletion:(SaveImageCompletion)completion
{
    __block BOOL albumWasFound = NO;
    
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                            if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
                                albumWasFound = YES;
                                
                                [self assetForURL:assetURL
                                      resultBlock:^(ALAsset *asset) {
                                          [group addAsset:asset];
                                          completion(nil);
                                      } failureBlock:completion];
                                
                                return;
                            }
                            
                            if (!group && !albumWasFound) {
                                __weak ALAssetsLibrary *weakSelf = self;
                                
                                [self addAssetsGroupAlbumWithName:albumName
                                                      resultBlock:^(ALAssetsGroup *group) {
                                                          [weakSelf assetForURL:assetURL
                                                                    resultBlock:^(ALAsset *asset) {
                                                                        [group addAsset:asset];
                                                                        completion(nil);
                                                                    } failureBlock:completion];
                                                      } failureBlock:completion];
                                
                                return;
                            }
                        } failureBlock:completion];
}

- (NSString *)imagePathWithExtension:(NSString *)extension
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh_mm_SSSSZ"];
    
    NSString *directory = [self imagesDirectory];
    
    if (!directory) {
        return nil;
    }
    
    NSString *fileName = [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingPathExtension:extension];
    NSString *filePath = [directory stringByAppendingString:fileName];
    
    return filePath;
}

- (NSString *)imagesDirectory
{
    NSMutableString *imagesPath = [[NSMutableString alloc] init];
    
    [imagesPath appendString:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask,
                                                                  YES) lastObject]];
    
    [imagesPath appendString:@"/Images/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagesPath]) {
        NSError *error = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:imagesPath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
        
        if (error) {
#ifdef NZDEBUG
            NSLog(@"%s Create directory \"%@\" with error: %@",
                  __PRETTY_FUNCTION__, imagesPath, error);
#endif
            return nil;
        }
    }
    
    return imagesPath;
}

- (NSString *)jpgPath
{
    return [self imagePathWithExtension:@"jpg"];
}

- (NSString *)pngPath
{
    return [self imagePathWithExtension:@"png"];
}

@end