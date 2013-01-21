//
//  RealTimeImagePicker.m
//  CamTranslator
//
//  Created by wenqing zhou on 2/7/12.
//  Copyright (c) 2012 university of helsinki. All rights reserved.
//



#import "RealTimeImagePicker.h"
#import <CoreGraphics/CoreGraphics.h>

#include "environ.h"
#import "pix.h"

@implementation RealTimeImagePicker

@synthesize captureSessionManager,progressBar,wordLabel,explainationView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(RealTimeImagePicker *)init
{
    self=[super init];
    if (self) {
        isRecognizing=NO;
        wordLabel=[[UILabel alloc] init];
        [wordLabel setBackgroundColor:[UIColor clearColor]];
        [wordLabel setFont:[UIFont systemFontOfSize:24]];
        [wordLabel setTextColor:[UIColor grayColor]];
        [wordLabel setTextAlignment:UITextAlignmentCenter];
        explainationView=[[UITextView alloc] init];
        [explainationView setBackgroundColor:[UIColor clearColor]];
        [explainationView setFont:[UIFont systemFontOfSize:14]];
        [explainationView setScrollEnabled:NO];
        [explainationView setTextColor:[UIColor whiteColor]];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self adjustLayout:[[UIApplication sharedApplication] statusBarOrientation]];
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    // init the tesseract engine.
    tesseract=new tesseract::TessBaseAPI();;
    tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "fin");
    
    captureSessionManager=[[CaptureSessionManager alloc] init];
    captureSessionManager.delegate=self;
    [captureSessionManager setTakingInterval:5];
    [captureSessionManager addVideoInput];
    [captureSessionManager addVideoPreviewLayer];
    [captureSessionManager addStillImageOutput];
    CGRect layerRect = [[[self view] layer] bounds];
	[[[self captureSessionManager] previewLayer] setBounds:layerRect];
	[[[self captureSessionManager] previewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                                                CGRectGetMidY(layerRect))];
	[[[self view] layer] addSublayer:[[self captureSessionManager] previewLayer]];
    [[captureSessionManager captureSession] startRunning];
    [captureSessionManager startTakingPicture];
    UIImageView *focusAreaView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus.png"]];
    [focusAreaView setFrame:CGRectMake(self.view.center.x-100, self.view.center.y-50, 200 , 100)];
    [self.view addSubview:focusAreaView];
    [self.view addSubview:self.wordLabel];
    [self.view addSubview:self.explainationView];
}

- (void)realTimeImageTaken:(UIImage *)image
{
    float widthRate=image.size.width/self.view.frame.size.width;
    float heightRate=image.size.height/self.view.frame.size.height;
    CGRect rect = CGRectMake(image.size.height/2-50*heightRate, image.size.width/2-100*widthRate, 
                            100*heightRate, 200*widthRate);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    
    imageRef=[Utilites CGImageRotatedByAngle:imageRef angle:270];
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    UIImageView *imageView=[[UIImageView alloc] initWithImage:result];
    [imageView setFrame:CGRectMake(0, 0, 200, 100)];
    [self.view addSubview:imageView];
    
    if (!isRecognizing) {
        self.progressBar=[[MBProgressHUD alloc] initWithView:self.view];
        [self.progressBar showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:result animated:YES];
        self.progressBar.labelText = @"Recognizing...";
        [self.view addSubview:self.progressBar];
        self.progressBar=nil;
    }
}

- (void)processOcrAt:(UIImage *)image
{
    isRecognizing=YES;
    [self setTesseractImage:image];
    tesseract->Recognize(NULL);
    char* utf8Text = tesseract->GetUTF8Text();
    [self performSelectorOnMainThread:@selector(ocrProcessingFinished:)
                           withObject:[NSString stringWithUTF8String:utf8Text]
                        waitUntilDone:NO];
}

- (void)ocrProcessingFinished:(NSString *)result
{
    NSLog(@"result:%@",result);
    [self.wordLabel setText:result];
    isRecognizing=NO;
}

- (void)setTesseractImage:(UIImage *)image
{
    free(pixels);
    
    CGSize size = [image size];
    int width = size.width;
    int height = size.height;
	
	if (width <= 0 || height <= 0)
		return;
	
    // the pixels will be painted to this array
    pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace, 
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// we're done with the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
}

- (void)adjustLayout:(UIInterfaceOrientation)orientation
{
    CGRect wordLabelRect;
    CGRect explainViewRect;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            wordLabelRect=CGRectMake(50, 100, 260, 50);
            explainViewRect=CGRectMake(110, 300, 100, 100);
            break;
            
        default:
            break;
    }
    [self.wordLabel setFrame:wordLabelRect];
    [self.explainationView setFrame:explainViewRect];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc
{
    self.wordLabel=nil;
    self.explainationView=nil;
    self.progressBar=nil;
    self.captureSessionManager=nil;
    delete tesseract;
    tesseract = nil;
    [super dealloc];
}

@end
