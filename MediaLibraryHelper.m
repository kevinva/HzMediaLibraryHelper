//
//  MediaLibraryHelper.m
//  Biando
//
//  Created by 何 峙 on 13-1-9.
//  Copyright (c) 2013年 biando. All rights reserved.
//

#import "MediaLibraryHelper.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

#define KevinDebug

@interface MediaLibraryHelper () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MPMediaPickerControllerDelegate>

- (BOOL)isMediaLibraryAvailable;
- (BOOL)canUserPickPhotosFromMediaLibrary;
- (BOOL)canUserPickVideosFromMediaLibrary;
- (BOOL)cameraSupportsMedia:(NSString *)paramMeidaType sourceType:(UIImagePickerControllerSourceType)paramSourceType;

@end

@implementation MediaLibraryHelper

- (void)dealloc{
    self.delegate = nil;
    self.rootViewController = nil;
    
    [super dealloc];
}

#pragma mark - Public Methods

- (void)showPhotoLibrary{
    if([self isMediaLibraryAvailable] && [self canUserPickPhotosFromMediaLibrary]){
        if(_rootViewController){
            UIImagePickerController *pickerVC = [[[UIImagePickerController alloc] init] autorelease];
            pickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            pickerVC.mediaTypes = @[(NSString *)kUTTypeImage];
            pickerVC.delegate = self;
            [_rootViewController presentViewController:pickerVC animated:YES completion:nil];
        }
    }
}

- (void)showVideoLibrary{
    if([self isMediaLibraryAvailable] && [self canUserPickVideosFromMediaLibrary]){
        if(_rootViewController){
            UIImagePickerController *pickerVC = [[[UIImagePickerController alloc] init] autorelease];
            pickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            pickerVC.mediaTypes = @[(NSString *)kUTTypeMovie];
            pickerVC.delegate = self;
            [_rootViewController presentViewController:pickerVC animated:YES completion:nil];
        }
    }
}

- (void)showAudioLibrary{
    if(!_rootViewController){
        return;
    }
    
    MPMediaPickerController *mpc = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAny] autorelease];
    mpc.delegate = self;
    mpc.prompt = @"Please select a music";
    mpc.allowsPickingMultipleItems = NO;
    [_rootViewController presentViewController:mpc animated:YES completion:nil];
}


#pragma mark - Private Methods

- (BOOL)isMediaLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)canUserPickPhotosFromMediaLibrary{
    return [self cameraSupportsMedia:(NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)canUserPickVideosFromMediaLibrary{
    return [self cameraSupportsMedia:(NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)cameraSupportsMedia:(NSString *)paramMeidaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if(paramMeidaType.length == 0){
        return NO;
    }
    
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *mediaType = (NSString *)obj;
        if([mediaType isEqualToString:paramMeidaType]){
            result = YES;
            *stop = YES;
        }
        
    }];
    
    return result;
}

#pragma mark - UIImagePickerControllerDelegate delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if(_rootViewController){
        [_rootViewController dismissViewControllerAnimated:YES completion:^{
            
#ifdef KevinDebug
            NSLog(@"%s, info: %@", __FUNCTION__, info);
#endif
            
            NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
            if([mediaType isEqualToString:(NSString *)kUTTypeImage]){
                UIImage *resultImage = [info objectForKey:UIImagePickerControllerOriginalImage];
                if(_delegate && [_delegate respondsToSelector:@selector(mediaLibrary:didPickPhoto:)]){
                    //            NSData *photoData = UIImagePNGRepresentation(resultImage);
                    NSData *photoData = UIImageJPEGRepresentation(resultImage, 1.0f);
                    [_delegate mediaLibrary:self didPickPhoto:photoData];
                }
                
                if(_delegate && [_delegate respondsToSelector:@selector(mediaLibrary:finishGettingPhotoGPSInfoWithLatitude:longitude:)]){
                    __block NSMutableDictionary *imageMetadata = nil;
                    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
                    ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];
                    [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        
                        imageMetadata = [[[NSMutableDictionary alloc] initWithDictionary:asset.defaultRepresentation.metadata] autorelease];
                        NSDictionary *gpsDict = [imageMetadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
                        if(gpsDict){
                            float latitude = [[gpsDict objectForKey:@"Latitude"] floatValue];
                            float longitude = [[gpsDict objectForKey:@"Longitude"] floatValue];
                            [_delegate mediaLibrary:self finishGettingPhotoGPSInfoWithLatitude:latitude longitude:longitude];
                        }
                        
                    } failureBlock:^(NSError *error) {
                        
#ifdef KevinDebug
                        NSLog(@"fail reading asset!");
#endif
                        
                    }];
                }
            }
            else if([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
                NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
                if(_delegate && [_delegate respondsToSelector:@selector(mediaLibrary:didPickVideo:)]){            
                    NSData *videoData = [NSData dataWithContentsOfURL:videoUrl];
                    [_delegate mediaLibrary:self didPickVideo:videoData];
                }
            }
            
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    if(_rootViewController){
        [_rootViewController dismissViewControllerAnimated:YES completion:^{
            
            if([_delegate respondsToSelector:@selector(didCancelMediaLibrary:)]){
                [_delegate didCancelMediaLibrary:self];
            }
            
        }];
    }
}

@end
