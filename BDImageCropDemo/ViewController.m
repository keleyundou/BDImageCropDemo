//
//  ViewController.m
//  BDImageCropDemo
//
//  Created by 冰点 on 15/12/21.
//  Copyright © 2015年 冰点. All rights reserved.
//

#import "ViewController.h"

#import "BDImagePickerController.h"

@interface ViewController ()<UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIButton *headButton;
@property (nonatomic, strong) BDImagePickerController *imagePickerController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak __typeof(self)weakSelf = self;
    self.imagePickerController.RTPickImageHandler = ^(UIImage *img) {
        [weakSelf.headButton setBackgroundImage:img forState:UIControlStateNormal];
    };
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)button:(id)sender {
    //-Wdeprecated-declarations
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    UIActionSheet *choiceSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"取消"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"拍照", @"从相册中选取", nil];
    [choiceSheet showInView:self.view];
#pragma clang diagnostic pop
}

#pragma mark UIActionSheetDelegate
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
#pragma clang diagnostic pop
    if (buttonIndex == 0) {
        // 拍照
        if ([self.imagePickerController isCameraAvailable] && [self.imagePickerController doesCameraSupportTakingPhotos]) {
            UIImagePickerController *controller = [self imagePickerController];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            if ([self.imagePickerController isFrontCameraAvailable]) {
                controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
            [self presentViewController:controller animated:YES completion:NULL];
        }
        
    } else if (buttonIndex == 1) {
        // 从相册中选取
        if ([self.imagePickerController isPhotoLibraryAvailable]) {
            UIImagePickerController *controller = [self imagePickerController];
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:controller animated:YES completion:NULL];
        }
    }
}

- (BDImagePickerController *)imagePickerController
{
    if (!_imagePickerController) {
        _imagePickerController = [[BDImagePickerController alloc] init];
    }
    return _imagePickerController;
}
@end
