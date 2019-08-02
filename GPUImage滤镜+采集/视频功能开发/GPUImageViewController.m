//
//  GPUImageViewController.m
//  视频功能开发
//
//  Created by mac on 2019/7/18.
//  Copyright © 2019 cc. All rights reserved.
//

#import "GPUImageViewController.h"
#import "GPUImage.h"
#import <Masonry.h>
#import "ReactiveObjC.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "filterView.h"
#import "FIlterManager.h"
#import "CCGPUImageVideoCamera.h"
#import "CCGPUImageRawDataOutput.h"

@interface GPUImageViewController ()<GPUImageVideoCameraDelegate,GPUImageMovieWriterDelegate,UIGestureRecognizerDelegate,CCGPUImageRawDataOutputDelegate,CCGPUImageVideoCameraDelegate>

@property (nonatomic, strong) CCGPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) CCGPUImageRawDataOutput* videoDataOutput;//获取输出视频数据

@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) GPUImageFilter* currentfilter;
@property (nonatomic, strong) dispatch_queue_t recordQueue;

@property (nonatomic, strong) UIImageView* focusImage;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *cameraPositionBtn;
@property (nonatomic, strong) UIButton *flashBtn;
@property (nonatomic, strong) filterView *filterConfigView;
@property (nonatomic, strong) FIlterManager *filterManager;

@end

@implementation GPUImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.filterView];
    [self.filterView addSubview:self.playBtn];
    [self.filterView addSubview:self.cameraPositionBtn];
    [self.filterView addSubview:self.flashBtn];
    [self.filterView addSubview:self.filterConfigView];
    
    [self.videoCamera addTarget:self.filterView];
    [self.filterView addSubview:self.focusImage];
    self.focusImage.hidden = YES;

    //获取转码后的视频 输出的图片格式为BGRA
    [self.videoCamera addTarget:self.videoDataOutput];
    
    _recordQueue = dispatch_queue_create("com.test.recordQueue", DISPATCH_QUEUE_SERIAL);
    
    [self callBack];
}

- (void)callBack{
    //聚焦手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] init];
    tapGesture.delegate = self;
    [[tapGesture rac_gestureSignal] subscribeNext:^(id x) {
        NSLog(@"%@", NSStringFromCGPoint([tapGesture locationInView:self.filterView]));
        CGPoint point = [tapGesture locationInView:self.filterView];
        [self showFouceView:point];
        CGPoint focusPoint = CGPointMake(point.x/self.filterView.frame.size.width, point.y/self.filterView.frame.size.height);
        [self setFocusPoint:focusPoint];
    }];
    
    //捏合手势
    UIPinchGestureRecognizer *doubleTapGesture = [[UIPinchGestureRecognizer alloc]init];
    doubleTapGesture.delegate = self;
    doubleTapGesture.delaysTouchesBegan = YES;
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    [[doubleTapGesture rac_gestureSignal] subscribeNext:^(id x) {
        CGFloat scale = doubleTapGesture.scale;
        doubleTapGesture.scale = MAX(1.0, scale);
        if (scale < 1.0f || scale > 3.0)
            return;
        NSLog(@"捏合%f",scale);
        [self setVideoScaleAndCropFactor:scale];
    }];
    
    [self.filterView addGestureRecognizer:tapGesture];
    [self.filterView addGestureRecognizer:doubleTapGesture];
    
    [[self.playBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        if (self.playBtn.isSelected) {
            [self.playBtn setTitle:@"录制" forState:UIControlStateNormal];
            [self stopRecord];
        }else{
            [self.playBtn setTitle:@"停止" forState:UIControlStateNormal];
            [self startRecord];
        }
        self.playBtn.selected = !self.playBtn.selected;
    }];
    
    //前后置
    [[self.cameraPositionBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        [self.videoCamera rotateCamera];
    }];
    
    //闪光灯
    [[self.flashBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        
        if (self.videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
            [self setFlash];
        }
    }];
    
    //点击滤镜
    self.filterConfigView.selectBlock = ^(NSInteger index) {
        [self.videoCamera removeAllTargets];
        self.currentfilter = [self addFilterWithIndex:index];
        if (self.currentfilter) {
            [self.videoCamera addTarget:self.currentfilter];
            [self.currentfilter addTarget:self.filterView];
            [self.currentfilter addTarget:self.videoDataOutput];
        }else{
            [self.videoCamera addTarget:self.filterView];
        }
        
    };
}

-(void)viewWillAppear:(BOOL)animated{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.videoCamera startCameraCapture];
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.videoCamera stopCameraCapture];
}


-(void)viewWillLayoutSubviews{
    [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-20);
        make.width.height.equalTo(@(60));
    }];
    
    [self.cameraPositionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.centerY.equalTo(self.playBtn);
        make.right.equalTo(self.view).offset(-40);
    }];
    
    [self.flashBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(20);
        make.height.equalTo(@(40));
        make.width.equalTo(@(60));
    }];
}

- (id)addFilterWithIndex:(NSInteger)index{
    id filter;
    if (index == 1){filter = [self.filterManager addFilter_Sketch];}
    if (index == 2){filter = [self.filterManager addFilter_Beautify];}
    if (index == 3){filter = [self.filterManager addFilter_Gamma];}
    if (index == 4){filter = [self.filterManager addFilter_ColorInvert];}
    if (index == 5){filter = [self.filterManager addFilter_Sepia];}
    if (index == 6){filter = [self.filterManager addFilter_Grayscale];}
    if (index == 7){filter = [self.filterManager addFilter_HistogramGenerator];}
    if (index == 8){filter = [self.filterManager addFilter_RGB];}
    if (index == 9){filter = [self.filterManager addFilter_Monochrome];}
    if (index == 10){filter = [self.filterManager addFilter_SobelEdgeDetection];}
    if (index == 11){filter = [self.filterManager addFilter_XYDerivative];}
    if (index == 12){filter = [self.filterManager addFilter_SmoothToon];}
    if (index == 13){filter = [self.filterManager addFilter_ColorPacking];}
    
    return filter;
}

//聚焦动画
- (void)showFouceView:(CGPoint)point{
    
    self.focusImage.bounds = CGRectMake(0, 0, 70, 70);
    self.focusImage.center = point;
    self.focusImage.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.focusImage.bounds = CGRectMake(0, 0, 50, 50);
    } completion:^(BOOL finished) {
        self.focusImage.hidden = YES;
    }];
}

//聚焦点
- (void)setFocusPoint:(CGPoint)point {
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

//设置焦距
- (void)setVideoScaleAndCropFactor:(float)scale{
    AVCaptureDevice *captureDevice = self.videoCamera.inputCamera;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        [captureDevice rampToVideoZoomFactor:scale withRate:10];
    }
}

//闪光灯切换
- (void)setFlash{
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        if (self.videoCamera.inputCamera.torchMode == AVCaptureTorchModeOn) {
            [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        }else{
            [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        }
        
    }];
}

//改变设备属性前一定要首先调用lockForConfiguration方法加锁,调用完之后使用unlockForConfiguration方法解锁.
-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    
    //也可以直接用_videoDevice,但是下面这种更好
    AVCaptureDevice *captureDevice = self.videoCamera.inputCamera;
    NSError *error;
    
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (lockAcquired) {
        [self.videoCamera.captureSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [self.videoCamera.captureSession commitConfiguration];
    }else{
        NSLog(@"设备解锁失败");
    }
}


- (NSURL*)fileUrl{
    NSString* docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString* path = [docPath stringByAppendingString:@"/1.mp4"];
    return [NSURL fileURLWithPath:path];
}


//开始录制
- (void)startRecord{
    
    dispatch_sync(_recordQueue, ^{
        [[NSFileManager defaultManager]removeItemAtURL:[self fileUrl] error:nil];

        if (self.currentfilter) {
            [self.currentfilter addTarget:self.movieWriter];
        }else{
            [self.videoCamera addTarget:self.movieWriter];
        }
        self.videoCamera.audioEncodingTarget = self.movieWriter;

        [self.movieWriter startRecording];
    });
}

- (void)stopRecord{
    
    dispatch_sync(_recordQueue, ^{
        [self.videoCamera removeTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = nil;
        [self.movieWriter finishRecordingWithCompletionHandler:^{
            self.movieWriter = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                AVPlayerViewController* vc = [[AVPlayerViewController alloc] init];
                vc.player = [[AVPlayer alloc] initWithURL:[self fileUrl]];
                [self.navigationController pushViewController:vc animated:YES];
            });
        }];
    });
}


#pragma mark -------------- CCGPUImageVideoCameraDelegate --------------
//音频数据
-(void)processAudioSample:(CMSampleBufferRef)sampleBuffer{
    //NSLog(@"---audio:%lld",pts.value/pts.timescale);//44100
}

#pragma mark -------------- CCGPUImageRawDataOutputDelegate --------------
//视频数据
-(void)newFrameReadyAtTime:(CMTime)frameTime andSize:(CGSize)imageSize andData:(uint8_t *)rawBytesForImage{
    //NSLog(@"---video:%lld",frameTime.value/frameTime.timescale);//1000000000
}

#pragma mark -------------- GPUImageMovieWriterDelegate --------------
-(void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
}

#pragma mark -------------- UIGestureRecognizerDelegate --------------
//防止手势冲突
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"GPUImageView"]) {
        return YES;
    }
    return  NO;
}

-(GPUImageMovieWriter *)movieWriter{
    if (!_movieWriter) {
        
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[self fileUrl] size:self.filterView.sizeInPixels];
        _movieWriter.encodingLiveVideo = YES;//实时采集的，需要设置yes
        
        //声音采集
        _movieWriter.shouldPassthroughAudio = YES;
        _movieWriter.hasAudioTrack=YES;
        _movieWriter.delegate = self;
    }
    return _movieWriter;
}

-(UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = [[UIButton alloc] init];
        _playBtn.backgroundColor = [UIColor redColor];
        [_playBtn setTitle:@"录制" forState:UIControlStateNormal];
        _playBtn.layer.cornerRadius = 30.0;
    }
    return _playBtn;
}

-(UIImageView *)focusImage{
    if (!_focusImage) {
        _focusImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"对焦"]];
    }
    return _focusImage;
}

-(UIButton *)cameraPositionBtn{
    if (!_cameraPositionBtn) {
        _cameraPositionBtn = [[UIButton alloc] init];
        _cameraPositionBtn.backgroundColor = [UIColor redColor];
        [_cameraPositionBtn setTitle:@"前后置" forState:UIControlStateNormal];
    }
    return _cameraPositionBtn;
}

-(filterView *)filterConfigView{
    if (!_filterConfigView) {
        _filterConfigView = [[filterView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100, 0, 100, 300)];
    }
    return _filterConfigView;
}

-(UIButton *)flashBtn{
    if (!_flashBtn) {
        _flashBtn = [[UIButton alloc] init];
        [_flashBtn setBackgroundColor: [UIColor redColor]];
        [_flashBtn setTitle:@"闪光灯" forState:UIControlStateNormal];
    }
    return _flashBtn;
}

-(GPUImageView *)filterView{
    if(!_filterView){
        _filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
        _filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    }
    return _filterView;
}

-(FIlterManager *)filterManager{
    if (!_filterManager) {
        _filterManager = [[FIlterManager alloc] init];
    }
    return _filterManager;
}

-(CCGPUImageVideoCamera *)videoCamera{
    if (!_videoCamera) {
        _videoCamera = [[CCGPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.delegate = self;
        _videoCamera.audioDelegate = self;
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;// 前置摄像头需要 镜像反转
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;// 后置摄像头不需要 镜像反转
        [_videoCamera addAudioInputsAndOutputs];//避免录制第一帧黑屏闪屏
        if ([_videoCamera.inputCamera lockForConfiguration:nil]) {
            //自动对焦
            if ([_videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [_videoCamera.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            //自动曝光
            if ([_videoCamera.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [_videoCamera.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            //自动白平衡
            if ([_videoCamera.inputCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                [_videoCamera.inputCamera setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
            [_videoCamera.inputCamera unlockForConfiguration];
        }
        
    }
    return _videoCamera;
}

-(CCGPUImageRawDataOutput *)videoDataOutput{
    if (!_videoDataOutput) {
        _videoDataOutput = [[CCGPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(720, 1280) resultsInBGRAFormat:YES];
        _videoDataOutput.dataDelegate = self;
    }
    return _videoDataOutput;
}


@end
