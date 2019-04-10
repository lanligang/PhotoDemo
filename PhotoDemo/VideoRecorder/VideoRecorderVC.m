//
//  VideoRecorderVC.m
//  PhotoDemo
//
//  Created by ios2 on 2019/4/9.
//  Copyright © 2019 ShanZhou. All rights reserved.
//

// 拍摄一张实况图片


#import "VideoRecorderVC.h"
#import <AVFoundation/AVFoundation.h>
#import "LivePhotoMaker.h"

@interface VideoRecorderVC ()<AVCaptureFileOutputRecordingDelegate>
{
	AVCaptureSession *_captrueSession;                           //会话
	AVCaptureDeviceInput * _videoCaptureDeviceInput;  //视频输入
	AVCaptureDeviceInput * _audioCaptureDeviceInput;  //音频输入
	AVCaptureMovieFileOutput * _videoFileOutput;         //视频输出
	AVCaptureVideoPreviewLayer * _captureVideoPreviewLayer;//预览图层
}
@end

@implementation VideoRecorderVC

- (void)viewDidLoad {
    [super viewDidLoad];
	/*
	 AVFoundation 框架用于创建和播放基于时间的影音媒体，可用来体验、创建、编辑媒体文件，也可以获取设备的输入流并在实时捕获和回放期间操作视频
	 为了管理来自设备的捕获，例如相机、麦克风等
	 AVCaptureDevice实例来代表输入设备，例如相机或麦克风。
	 AVCaptureInput具体子类的实例来从输入设备配置端口。
	 AVCaptureOutput具体子类的实例来管理输出成视频文件或照片。
	 AVCaptureSession实例来协调从输入到输出的数据流。
	 AVCaptureVideoPreviewLayer图层实例来显示用户的预览视频记录。
	 */

	[self initAVcaotureSession];
	//能够运行显示了
	[self initVideoCaptureDevice];
	//创建一个开始录制的按钮
	[self initBtn];

}
//创建一个开始录制的按钮
-(void)initBtn
{
	UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.view addSubview:startBtn];
	startBtn.bounds = CGRectMake(0, 0, 60, 60);
	startBtn.center = self.view.center;
	CGRect frame = startBtn.frame;
	frame.origin.y = CGRectGetHeight(self.view.bounds) - 100;
	startBtn.frame = frame;
	[startBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
	startBtn.backgroundColor = [UIColor redColor];
	startBtn.layer.cornerRadius =  30;
	startBtn.layer.masksToBounds = YES;
}
-(void)btnClicked:(UIButton *)btn
{
	btn.selected = !btn.selected;
	if (btn.isSelected) {
		AVCaptureConnection *connection = [_videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
		// 预览图层和视频方向保持一致,这个属性设置很重要，如果不设置，那么出来的视频图像可以是倒向左边的。
		connection.videoOrientation = [[_captureVideoPreviewLayer connection] videoOrientation];
		NSString *str = [NSString stringWithFormat:@"video%.2f.mov",[[NSDate date] timeIntervalSince1970]];
		NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingString:str];
		//路径转换成YRK
		NSURL *fileUrl = [NSURL fileURLWithPath:outputFilePath];
		[_videoFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];

	}else{
		[_videoFileOutput stopRecording];
	}
}

-(void)initAVcaotureSession
{
	//AVCaptureSession : 媒体 捕获会话  负责把捕获的音视频数据输出到输出设备中一个 AVCaptureSession
	if (!_captrueSession) {
		AVCaptureSession *captrueSession = [AVCaptureSession new];
		_captrueSession = captrueSession;
		if ([captrueSession canSetSessionPreset:(AVCaptureSessionPreset640x480)]) {
			[captrueSession setSessionPreset:AVCaptureSessionPreset640x480];
		}

	}
}

-(void)initVideoCaptureDevice
{
	AVCaptureDevice *device = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
	if (!device)  return;
	AVCaptureDevice *adioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
	//通过 AVCaptureDevice 初始化 音频、视频 输入对象
	NSError *videoError = nil;
	_videoCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:device error:&videoError];
	if (videoError) {
		NSLog(@"输入设备出现问题| %@",videoError);
		return;
	}
	NSError *audioError = nil;
	_audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:adioCaptureDevice error:&audioError];
	if (audioError) {
		NSLog(@"输入设备出现问题| %@",audioError);
		return;
	}
/*初始化输出数据管理对象 ，如果要拍照就初始化
 AVCaptureStillImageOutput
 如果拍摄视频 就初始化
 AVCaptureMovieFileOutput
 */
	_videoFileOutput = [[AVCaptureMovieFileOutput alloc]init];

	/*
	 将数据输入对象 AVCaptureDeviceInput 、数据输出对象 AVCaptureFileOutput
	 添加到媒体会话管理对象 AVCaptureSession 中
	 */

	if ([_captrueSession canAddInput:_videoCaptureDeviceInput]) {
		[_captrueSession addInput:_videoCaptureDeviceInput];
	}

	if ([_captrueSession canAddInput:_audioCaptureDeviceInput]) {
		[_captrueSession addInput:_audioCaptureDeviceInput];
		AVCaptureConnection *captureConnection = [_videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
		//标识视频录入时稳定音频流的接收，这里设置为自动
		if ([captureConnection isVideoStabilizationSupported]) {
			captureConnection.preferredVideoStabilizationMode =  AVCaptureVideoStabilizationModeAuto;
		}
	}
	if ([_captrueSession canAddOutput:_videoFileOutput]) {
		[_captrueSession addOutput:_videoFileOutput];
	}
/*
创建视频预览图层  AVCaptureVideoPreviewLayer
 并指定媒体会话，添加图层到显示容器中，
 调用 AVCaptureSession 的 startRuning 方法开始捕获
 */
	AVCaptureVideoPreviewLayer * captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captrueSession];
	_captureVideoPreviewLayer = captureVideoPreviewLayer;
	CALayer *layer = self.view.layer;
	layer.masksToBounds = YES;
	captureVideoPreviewLayer.frame = layer.bounds;
	captureVideoPreviewLayer.masksToBounds = YES;
	captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
	[layer addSublayer:captureVideoPreviewLayer];
	[_captrueSession startRunning];

}

-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)positon
{
	NSArray  *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if (device.position == positon) {
			return device;
		}
	}
	return nil;
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error
{
	NSLog(@" didFinishRecordingToOutputFileAtURL |%@",outputFileURL);
	__weak typeof(self)ws = self;
	 dispatch_async(dispatch_get_main_queue(), ^{
		 __strong typeof(ws)ss = ws;
		 [ss creactAndSaveLivePhoto:outputFileURL];
	 });
//	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//			// 需要在主线程执行的代码
//
//	});

}
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections
{
	NSLog(@" ------------------  |didStartRecordingToOutputFileAtURL");
}
-(void)creactAndSaveLivePhoto:(NSURL *)url
{
	[_captrueSession stopRunning];
	__weak typeof(self)ws = self;
	if ([url isKindOfClass:[NSURL class]]) {
		[LivePhotoMaker makeLivePhotoByLibrary:url completed:^(NSDictionary *resultDic) {
			if (resultDic) {
				NSURL * videoUrl = resultDic[@"MOVPath"];
				NSURL * imageUrl = resultDic[@"JPGPath"];
				if (videoUrl&&imageUrl) {
					[LivePhotoMaker saveLivePhotoToAlbumWithMovPath:videoUrl ImagePath:imageUrl completed:^(BOOL isSuccess) {
						if (isSuccess) {
							 dispatch_async(dispatch_get_main_queue(), ^{
									// 需要在主线程执行的代码
								__strong typeof(ws)ss = ws;
								[ss.navigationController popViewControllerAnimated:YES];
							});
						}
					}];
				}
			}
		}];
	}
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
