//
//  ViewController.m
//  原生二维码扫描
//
//  Created by lushuishasha on 16/8/12.
//  Copyright © 2016年 lushuishasha. All rights reserved.
//  http://www.cnblogs.com/lzjsky/p/5057134.html

/*
 AVCaptureSession 管理输入(AVCaptureInput)和输出(AVCaptureOutput)流，包含开启和停止会话方法。
 AVCaptureDeviceInput 是AVCaptureInput的子类,可以作为输入捕获会话，用AVCaptureDevice实例初始化。
 AVCaptureDevice 代表了物理捕获设备如:摄像机。用于配置等底层硬件设置相机的自动对焦模式。
 AVCaptureMetadataOutput 是AVCaptureOutput的子类，处理输出捕获会话。捕获的对象传递给一个委托实现AVCaptureMetadataOutputObjectsDelegate协议。协议方法在指定的派发队列（dispatch queue）上执行。
 AVCaptureVideoPreviewLayerCALayer的一个子类，显示捕获到的相机输出流。
 */

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
//设置捕获会话
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (weak, nonatomic) IBOutlet UIButton *lightButton;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIView *scanFrameView;
@property (nonatomic) BOOL lastResult;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [_button setTitle:@"开始" forState:UIControlStateNormal];
    [_lightButton setTitle:@"打开照明" forState:UIControlStateNormal];
    _lastResult = YES;
}

- (void)dealloc{
    //停止读取
    [self stopReading];
}

//创建会话，读取输入流
- (BOOL)startReading {
    [_button setTitle:@"停止" forState:UIControlStateNormal];
    //获取AVCaptureDevice实例
    NSError *error;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建会话
    _captureSession = [[AVCaptureSession alloc]init];
    
    //初始化输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@",[error localizedDescription]);
        return NO;
    }
    
    //添加输入流
    [_captureSession addInput:input];
    
    // 初始化输出流
    AVCaptureMetadataOutput *captureMetadatOutput = [[AVCaptureMetadataOutput alloc]init];
    
    // 添加输出流
    [_captureSession addOutput:captureMetadatOutput];
    
    // 创建dispatch queue.
    //dispatch_queue_t dispatchQueue;
    //dispatchQueue = dispatch_queue_create(kScanQRCodeQueueName, NULL)
    [captureMetadatOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 设置元数据类型 AVMetadataObjectTypeQRCode
    [captureMetadatOutput setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeQRCode, nil]];
    
    //创建输出对象
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captureSession];
    
    //A string defining how the video is displayed within an AVCaptureVideoPreviewLayer bounds rect.
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_scanFrameView.bounds];
    [_scanFrameView.layer addSublayer:_videoPreviewLayer];
    
    //开始会话
    [_captureSession startRunning];
    return YES;
}

- (void)stopReading {
    [_button setTitle:@"开始" forState:UIControlStateNormal];
    
    [_captureSession stopRunning];
    _captureSession = nil;
}


//:处理结果
- (void)repotrScanResult:(NSString *)result{
    [self stopReading];
    if (!_lastResult){
        return;
    }
    _lastResult = NO;
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"二维码扫描"
                                                   message:result
                                                  delegate:nil
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:nil];
    [alert show];
    
    // 以下处理了结果，继续下次扫描
    _lastResult = YES;
}



//开启系统照明
- (void)systemLightSwitch:(BOOL)open{
    if (open) {
        [_lightButton setTitle:@"关闭照明" forState:UIControlStateNormal];
    } else {
        [_lightButton setTitle:@"打开照明" forState:UIControlStateNormal];
    }
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (open){
            [device setTorchMode:AVCaptureTorchModeOn];
        }else{
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        
        [device unlockForConfiguration];
    }
}

#pragma AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0){
        AVMetadataMachineReadableCodeObject *medataObj = [metadataObjects objectAtIndex:0];
        NSString *result;
        if ([[medataObj type] isEqualToString:AVMetadataObjectTypeQRCode]){
            result = medataObj.stringValue;
        }else{
            NSLog(@"不是二维码");
        }
        [self performSelectorOnMainThread:@selector(repotrScanResult:) withObject:result waitUntilDone:nil];
    }
}


- (IBAction)startScanner:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"开始"]){
        [self startReading];
    }else{
        [self stopReading];
    }
}


- (IBAction)openSystemLight:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"打开照明"]){
        [self systemLightSwitch:YES];
    }else{
        [self systemLightSwitch:NO];
    }
}

@end
