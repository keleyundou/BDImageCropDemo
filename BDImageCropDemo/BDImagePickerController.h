//
//  BDImagePickerController.h
//  BDImageCropDemo
//
//  Created by ColaBean on 17/3/24.
//  Copyright © 2017年 冰点. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BDImagePickerController : UIImagePickerController

- (BOOL)isCameraAvailable;
- (BOOL)isRearCameraAvailable;
- (BOOL)isFrontCameraAvailable;
- (BOOL)doesCameraSupportTakingPhotos;
- (BOOL)isPhotoLibraryAvailable;
- (BOOL)canUserPickVideosFromPhotoLibrary;
- (BOOL)canUserPickPhotosFromPhotoLibrary;

@property (nonatomic, copy) void(^RTPickImageHandler)(UIImage *img);
@end
