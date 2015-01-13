//
//  MediaLibraryHelper.h
//  Biando
//
//  Created by 何 峙 on 13-1-9.
//  Copyright (c) 2013年 biando. All rights reserved.
//

//注：使用kCGImagePropertyGPSDictionary要包含ImageIO.framework

#import <Foundation/Foundation.h>

@import UIKit;

@protocol MediaLibraryHelperDelegate;

@interface MediaLibraryHelper : NSObject

@property (nonatomic, assign) id<MediaLibraryHelperDelegate> delegate;
@property (nonatomic, assign) UIViewController *rootViewController;

- (void)showPhotoLibrary;
- (void)showVideoLibrary;
- (void)showAudioLibrary;

@end

@protocol MediaLibraryHelperDelegate <NSObject>

@optional
- (void)mediaLibrary:(MediaLibraryHelper *)helper didPickPhoto:(NSData *)photoData;  //图片
- (void)mediaLibrary:(MediaLibraryHelper *)helper finishGettingPhotoGPSInfoWithLatitude:(float)latitude longitude:(float)longitude; //图片
- (void)mediaLibrary:(MediaLibraryHelper *)helper didPickVideo:(NSData *)videoData;   //视频
- (void)didCancelMediaLibrary:(MediaLibraryHelper *)helper;

@end
