#import <AVFoundation/AVFoundation.h>

#define kImageCapturedSuccessfully @"imageCapturedSuccessfully"

@protocol RealTimeImagePickerDelegate

- (void)realTimeImageTaken:(UIImage *)image;

@end


@interface CaptureSessionManager : NSObject {

}

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;
@property (retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) UIImage *stillImage;
@property int takingInterval;
@property (nonatomic, retain) NSTimer *timer;
@property (retain,nonatomic) id<RealTimeImagePickerDelegate> delegate;

- (void)addVideoPreviewLayer;
- (void)addVideoInput;
- (void)addStillImageOutput;
- (void)captureStillImage;
- (void)startTakingPicture;
@end
