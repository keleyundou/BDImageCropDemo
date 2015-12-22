//
//  BDImageCropViewController.h
//  BDImageCropDemo
//
//  Created by 冰点 on 15/12/21.
//  Copyright © 2015年 冰点. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BDImageCropViewController;

@protocol BDImageCropperDelegate <NSObject>

- (void)imageCropper:(BDImageCropViewController *)cropperViewController didFinished:(UIImage *)editedImage;
@optional

@end

@interface BDImageCropViewController : UIViewController

/*!
 *  @brief 裁剪控制器的初始化
 *
 *  @param sourceImage 源图
 *  @param cropSize    裁剪大小
 *  @param scaleRatio  缩放比率
 *
 *  @return BDImageCropViewController对象
 */
- (instancetype)initWithImage:(UIImage *)sourceImage cropSize:(CGSize)cropSize scaleRatio:(CGFloat)scaleRatio;

@property (nonatomic, assign) id <BDImageCropperDelegate> delegate;
@end
