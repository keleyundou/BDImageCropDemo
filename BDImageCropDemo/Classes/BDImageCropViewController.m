//
//  BDImageCropViewController.m
//  BDImageCropDemo
//
//  Created by 冰点 on 15/12/21.
//  Copyright © 2015年 冰点. All rights reserved.
//

#import "BDImageCropViewController.h"
#define ORIGINAL_MAX_WIDTH 640.0f

#define ScreenWidth  [UIScreen mainScreen].bounds.size.width
#define ScreenHeight  [UIScreen mainScreen].bounds.size.height
@interface BDImageCropViewController ()
{
    UIImage *_sourceImage;
    CGSize _cropSize;
    CGFloat _scaleRatio;
    
    CGRect oldFrame, latestFrame, largeFrame;
    CGRect _cropFrame;
}

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) UIView *toolBarView;
@end

@implementation BDImageCropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupSubViews];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
#pragma mark -
//MARK: Init
- (instancetype)initWithImage:(UIImage *)sourceImage
                     cropSize:(CGSize)cropSize
                   scaleRatio:(CGFloat)scaleRatio
{
    if (self = [super init]) {
        _sourceImage = [self imageByScalingToMaxSize:sourceImage];
        _cropSize = cropSize;
        _scaleRatio = scaleRatio;
    }
    return self;
}

- (void)setupSubViews
{
    [self addGestureRecognizers];
    
    [self.view addSubview:self.imageView];
    
    [self.view addSubview:self.overlayView];
    
    [self overlayCliping];
    
    [self.view addSubview:self.toolBarView];
}

//MARK: setter & getter
- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.multipleTouchEnabled = YES;
        _imageView.userInteractionEnabled = YES;
        _imageView.image = _sourceImage;
        _imageView.userInteractionEnabled = YES;
        _imageView.multipleTouchEnabled = YES;
        _imageView.frame = [self scaleFitScreenForSourceImageView];
        
    }
    return _imageView;
}

- (UIView *)overlayView
{
    if (!_overlayView) {
        _overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height )];
        _overlayView.userInteractionEnabled = YES;
        _overlayView.opaque = NO;
    }
    return _overlayView;
}

- (UIView *)toolBarView
{
    if (!_toolBarView) {
        _toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 64, CGRectGetWidth(self.view.frame), 64)];
        
        UIBezierPath * path= [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
        CAShapeLayer *layer = [CAShapeLayer layer];
        [path setUsesEvenOddFillRule:YES];
        layer.path = path.CGPath;
        layer.fillRule = kCAFillRuleEvenOdd;
        layer.fillColor = [[UIColor grayColor] CGColor];
        layer.opacity = 0.5;
        [_toolBarView.layer addSublayer:layer];
        //cancle
        UIButton *cancleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        cancleButton.titleLabel.textColor = [UIColor whiteColor];
        [cancleButton setTitle:@"取消" forState:UIControlStateNormal];
        [cancleButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
        [cancleButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [cancleButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [cancleButton setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        [cancleButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancleButton.frame = CGRectMake(0, 0, 100, 64);
        [_toolBarView addSubview:cancleButton];
        
        //confirm
        UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        confirmButton.titleLabel.textColor = [UIColor whiteColor];
        [confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [confirmButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
        [confirmButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [confirmButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [confirmButton setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        [confirmButton addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
        confirmButton.frame = CGRectMake(CGRectGetWidth(_toolBarView.frame) - 100, 0, 100, 64);
        [_toolBarView addSubview:confirmButton];
        _toolBarView.userInteractionEnabled = YES;
    }
    return _toolBarView;
}
//MARK: Action
- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)confirm:(id)sender {
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(BDImageCropperDelegate)]) {
        [self.delegate imageCropper:self didFinished:[self getSubImage]];
    }
}

// pinch gesture handler
- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = self.imageView;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }
    else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = self.imageView.frame;
        newFrame = [self handleScaleOverflow:newFrame];
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.frame = newFrame;
            latestFrame = newFrame;
        }];
    }
}

// pan gesture handler
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = self.imageView;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // calculate accelerator
        CGFloat absCenterX = (self.view.center.x - _cropSize.width/2) + _cropSize.width / 2;
        CGFloat absCenterY = (self.view.center.y - _cropSize.height/2) + _cropSize.height / 2;
        CGFloat scaleRatio = self.imageView.frame.size.width / _cropSize.width;
        CGFloat acceleratorX = 1 - ABS(absCenterX - view.center.x) / (scaleRatio * absCenterX);
        CGFloat acceleratorY = 1 - ABS(absCenterY - view.center.y) / (scaleRatio * absCenterY);
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x * acceleratorX, view.center.y + translation.y * acceleratorY}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // bounce to original frame
        CGRect newFrame = self.imageView.frame;
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.frame = newFrame;
            latestFrame = newFrame;
        }];
    }
}

//MARK: delegate

//MARK: Other

// scale to fit the screen
- (CGRect)scaleFitScreenForSourceImageView
{
    CGFloat targetWidth = _cropSize.width;
    CGFloat targetHeight = (_sourceImage.size.height / _sourceImage.size.width) * targetWidth;
    
    CGFloat targetX = /*_crop.x*/(self.view.center.x - _cropSize.width/2) + (_cropSize.width - targetWidth) / 2.0;
    CGFloat targetY = /*_crop.y*/(self.view.center.y - _cropSize.height/2) + (_cropSize.height - targetHeight) / 2.0;
    
    oldFrame = CGRectMake(targetX, targetY, targetWidth, targetHeight);
    latestFrame = oldFrame;
    largeFrame = CGRectMake((self.view.center.x - _cropSize.width/2), (self.view.center.y - _cropSize.height/2), _scaleRatio * oldFrame.size.width, _scaleRatio * oldFrame.size.height);
    return oldFrame;
}

// register all gestures
- (void) addGestureRecognizers
{
    // add pinch gesture
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    // add pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
}

- (void)overlayCliping
{
    CGPoint center = self.view.center;
    UIBezierPath * path= [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    CAShapeLayer *layer = [CAShapeLayer layer];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(center.x - (_cropSize.width/2.0), center.y - (_cropSize.height/2.0), _cropSize.width, _cropSize.height)]];
    [path setUsesEvenOddFillRule:YES];
    layer.path = path.CGPath;
    layer.fillRule = kCAFillRuleEvenOdd;
    layer.fillColor = [[UIColor blackColor] CGColor];
    layer.opacity = 0.5;
    [self.overlayView.layer addSublayer:layer];
}

- (CGRect)handleScaleOverflow:(CGRect)newFrame {
    // bounce to original frame
    CGPoint oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width/2, newFrame.origin.y + newFrame.size.height/2);
    if (newFrame.size.width < oldFrame.size.width) {
        newFrame = oldFrame;
    }
    if (newFrame.size.width > largeFrame.size.width) {
        newFrame = largeFrame;
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width/2;
    newFrame.origin.y = oriCenter.y - newFrame.size.height/2;
    return newFrame;
}

- (CGRect)handleBorderOverflow:(CGRect)newFrame {
    // horizontally
    if (newFrame.origin.x > (self.view.center.x - _cropSize.width/2)) newFrame.origin.x = (self.view.center.x - _cropSize.width/2);
    if (CGRectGetMaxX(newFrame) < _cropSize.width) newFrame.origin.x = _cropSize.width - newFrame.size.width;
    // vertically
    if (newFrame.origin.y > (self.view.center.y - _cropSize.height/2)) newFrame.origin.y = (self.view.center.y - _cropSize.height/2);
    if (CGRectGetMaxY(newFrame) < (self.view.center.y - _cropSize.height/2) + _cropSize.height) {
        newFrame.origin.y = (self.view.center.y - _cropSize.height/2) + _cropSize.height - newFrame.size.height;
    }
    // adapt horizontally rectangle
    if (self.imageView.frame.size.width > self.imageView.frame.size.height && newFrame.size.height <= _cropSize.height) {
        newFrame.origin.y = (self.view.center.y - _cropSize.height/2) + (_cropSize.height - newFrame.size.height) / 2;
    }
    return newFrame;
}

- (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage {
    if (sourceImage.size.width < ORIGINAL_MAX_WIDTH) return sourceImage;
    CGFloat btWidth = 0.0f;
    CGFloat btHeight = 0.0f;
    if (sourceImage.size.width > sourceImage.size.height) {
        btHeight = ORIGINAL_MAX_WIDTH;
        btWidth = sourceImage.size.width * (ORIGINAL_MAX_WIDTH / sourceImage.size.height);
    } else {
        btWidth = ORIGINAL_MAX_WIDTH;
        btHeight = sourceImage.size.height * (ORIGINAL_MAX_WIDTH / sourceImage.size.width);
    }
    CGSize targetSize = CGSizeMake(btWidth, btHeight);
    return [self imageByScalingAndCroppingForSourceImage:sourceImage targetSize:targetSize];
}

- (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

-(UIImage *)getSubImage{
    CGRect squareFrame = CGRectMake((self.view.center.x - _cropSize.width/2), (self.view.center.y - _cropSize.height/2), _cropSize.width, _cropSize.height);
    CGFloat scaleRatio = latestFrame.size.width / _sourceImage.size.width;
    CGFloat x = (squareFrame.origin.x - latestFrame.origin.x) / scaleRatio;
    CGFloat y = (squareFrame.origin.y - latestFrame.origin.y) / scaleRatio;
    CGFloat w = squareFrame.size.width / scaleRatio;
    CGFloat h = squareFrame.size.width / scaleRatio;
    if (latestFrame.size.width < _cropSize.width) {
        CGFloat newW = _sourceImage.size.width;
        CGFloat newH = newW * (_cropSize.height / _cropSize.width);
        x = 0; y = y + (h - newH) / 2;
        w = newH; h = newH;
    }
    if (latestFrame.size.height < _cropSize.height) {
        CGFloat newH = _sourceImage.size.height;
        CGFloat newW = newH * (_cropSize.width / _cropSize.height);
        x = x + (w - newW) / 2; y = 0;
        w = newH; h = newH;
    }
    CGRect myImageRect = CGRectMake(x, y, w, h);
    CGImageRef imageRef = _sourceImage.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    CGSize size;
    size.width = myImageRect.size.width;
    size.height = myImageRect.size.height;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myImageRect, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    return smallImage;
}
@end
