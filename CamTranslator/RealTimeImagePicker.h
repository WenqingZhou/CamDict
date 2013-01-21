//
//  RealTimeImagePicker.h
//  CamTranslator
//
//  Created by wenqing zhou on 2/7/12.
//  Copyright (c) 2012 university of helsinki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "CaptureSessionManager.h"
#import "MBProgressHUD.h"
#import "Utilites.h"

#ifdef __cplusplus
#include "baseapi.h"
using namespace tesseract;
#else
@class TessBaseAPI;
#endif

@interface RealTimeImagePicker : UIViewController<RealTimeImagePickerDelegate>
{
    TessBaseAPI *tesseract;
    uint32_t *pixels;
    BOOL isRecognizing;
}

@property (nonatomic,retain) CaptureSessionManager *captureSessionManager;
@property (nonatomic,retain) MBProgressHUD *progressBar;
@property (nonatomic,retain) UILabel *wordLabel;
@property (nonatomic,retain) UITextView *explainationView;

- (void)setTesseractImage:(UIImage *)image;
- (void)adjustLayout:(UIInterfaceOrientation)orientation;



@end
