//
//  PhotoBrowViewController.m
//  PhotoDemo
//
//  Created by ios2 on 2019/3/1.
//  Copyright © 2019 ShanZhou. All rights reserved.
//

#import "PhotoBrowViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "YYImage.h"
#import "NSData+ImageContentType.h"
#import "SDWebImageGIFCoder.h"
#import "UIImage+GIF.h"

#import "Header.h"

@interface PhotoBrowViewController ()<UIScrollViewDelegate>
@property (nonatomic,strong)UIScrollView *bgScrollView;
@property (nonatomic,strong)UIImageView *containtImgView;
@property (nonatomic,strong)NSURL *sourceUrl;
@property (nonatomic,strong)AVPlayer *avPlayer;
//时间监听  进度监听 ------
@property (nonatomic ,strong)  id timeObser;
@property (nonatomic,strong)UIProgressView *progressView;

@property (nonatomic,strong)UIImageView *playImgView;

@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;

@end

@implementation PhotoBrowViewController

- (void)viewDidLoad {

    [super viewDidLoad];
	NSString *name = [self.asset valueForKey:@"filename"];
	self.navigationItem.title = name;
	_bgScrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
	[self.view addSubview:self.bgScrollView];
	_bgScrollView.scrollsToTop = NO;
	_bgScrollView.delegate = self;
	_bgScrollView.maximumZoomScale = 2.5;
	_bgScrollView.minimumZoomScale = 0.5;
	self.view.backgroundColor = [UIColor blackColor];

	if (@available(iOS 11.0,*)) {
		_bgScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
	}else{
		self.automaticallyAdjustsScrollViewInsets = NO;
	}

	self.containtImgView = [[YYAnimatedImageView alloc]init];
	self.containtImgView.image = self.smallImg;
	self.containtImgView.contentMode = UIViewContentModeScaleAspectFit;

	[_bgScrollView addSubview:self.containtImgView];

	self.containtImgView.frame = _bgScrollView.bounds;
	self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleGray)];
	[self.view addSubview:self.activityIndicator];
		//设置小菊花的frame
	self.activityIndicator.frame= CGRectMake(100, 100, 100, 100);
		//设置小菊花颜色
	self.activityIndicator.color = [UIColor whiteColor];
		//设置背景颜色
	self.activityIndicator.backgroundColor = [UIColor clearColor];
	//刚进入这个界面会显示控件，并且停止旋转也会显示，只是没有在转动而已，没有设置或者设置为YES的时候，刚进入页面不会显示
	self.activityIndicator.hidesWhenStopped = YES;
	self.activityIndicator.center = self.view.center;
	[self.activityIndicator startAnimating];

	UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"分享" style:UIBarButtonItemStylePlain target:self action:@selector(share)];
	self.navigationItem.rightBarButtonItem = item;

	if (self.asset.mediaType == PHAssetMediaTypeImage) {
		__weak typeof(self)ws = self;
		if ([name hasSuffix:@".GIF"]) {
			[PhotoManager getGifImgData:self.asset andCompletion:^(NSData *data) {
				SDImageFormat format =	[NSData sd_imageFormatForImageData:data] ;
				if (format == SDImageFormatGIF) {
					ws.containtImgView.image = [[YYImage alloc]initWithData:data];
				}
				[ws.activityIndicator stopAnimating];
			}];
		}else{
			[PhotoManager getImageHighQualityForAsset:self.asset progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
			} resultHandler:^(UIImage *result, NSDictionary *info, BOOL isDownloadFinined) {
				if (isDownloadFinined) {
					ws.containtImgView.image = result;
					[ws.activityIndicator stopAnimating];
				}
			}];
		}
	}else if(self.asset.mediaType == PHAssetMediaTypeVideo) {
		//视频部分
		 AVPlayer *player = [[AVPlayer alloc]init];
		player.volume = 0.5;
		self.avPlayer = player;
		AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
		[self.containtImgView.layer addSublayer:layer];
		layer.frame = self.containtImgView.frame;
		[player addObserver:self forKeyPath:@"rate" options:(NSKeyValueObservingOptionNew) context:nil];

		layer.videoGravity = AVLayerVideoGravityResizeAspect;

		__weak typeof(self) ws = self;
		[PhotoManager getVideoOutputPathWithAsset:self.asset videoQuality:SmallVideoQuality success:^(NSString *outputPath) {
			ws.sourceUrl = [NSURL fileURLWithPath:outputPath];
			AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:outputPath]];
			[ws.avPlayer replaceCurrentItemWithPlayerItem:item];
			[ws.avPlayer play];
			[ws.activityIndicator stopAnimating];
		} failure:^(NSString *errorMessage, NSError *error) {
			
		}];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
		[self addTimeObserver];
		CGFloat y  = CGRectGetHeight(self.view.bounds) - 40.0;
		CGFloat w = CGRectGetWidth(self.view.bounds) - 50;
		self.progressView = [[UIProgressView alloc]initWithFrame:CGRectMake(25, y, w, 2)];
		self.progressView.progressTintColor = [UIColor greenColor];
		self.progressView.trackTintColor = [UIColor lightGrayColor];
		[self.view addSubview:self.progressView];
		self.playImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
		self.playImgView.center = self.containtImgView.center;
		self.playImgView.image = [UIImage imageNamed:@"player"];
		self.playImgView.hidden = YES;
		[self.containtImgView addSubview:self.playImgView];
			//激活音频会话
		[[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
		[[AVAudioSession sharedInstance]setActive:YES error:nil];
		UIBarButtonItem *saveLiveItem = [[UIBarButtonItem alloc]initWithTitle:@"LivePhoto" style:(UIBarButtonItemStylePlain) target:self action:@selector(saveLivePhotoAction)];
		UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"分享" style:UIBarButtonItemStylePlain target:self action:@selector(share)];
		self.navigationItem.rightBarButtonItems =@[item,saveLiveItem];
	}
	[_bgScrollView setZoomScale:0.8 animated:NO];
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTap:)];
	[self.view addGestureRecognizer:tap];
	if (self.asset.mediaType == PHAssetMediaTypeVideo) {
		//双击 -----
		tap.numberOfTapsRequired = 1;
	}else{
		tap.numberOfTapsRequired = 2;
	}

	[self.view bringSubviewToFront:self.activityIndicator];
}

-(void)saveLivePhotoAction
{
//	if (self.sourceUrl) {
//		[self creactAndSaveLivePhoto:self.sourceUrl];
//	}
	[self.avPlayer pause];
	Class vcClass = NSClassFromString(@"VideoRecorderVC");
	if (vcClass) {
		UIViewController *vc = [[vcClass alloc]init];
		[self.navigationController pushViewController:vc animated:YES];
	}
}

-(void)share
{
	if (self.asset.mediaType == PHAssetMediaTypeVideo) {
		__weak typeof(self)ws = self;
		[self.activityIndicator startAnimating];
		if (self.sourceUrl) {
			[self shareWithURL:self.sourceUrl];
			[self.activityIndicator stopAnimating];
		}else{
			[PhotoManager getVideoOutputPathWithAsset:self.asset videoQuality:SmallVideoQuality success:^(NSString *outputPath) {
				[ws shareWithURL:[NSURL fileURLWithPath:outputPath]];
				[ws.activityIndicator stopAnimating];
			} failure:^(NSString *errorMessage, NSError *error) {
			}];
		}
	} else {
		[self.activityIndicator startAnimating];
		NSString *name =	[self.asset valueForKey:@"filename"];
		__weak typeof(self)ws = self;
		if ([name hasSuffix:@".GIF"]) {
			[PhotoManager getGifImgData:self.asset andCompletion:^(NSData *data) {
				if (data) {
					[ws shareWithURL:data];
				}
				[ws.activityIndicator stopAnimating];
			}];
		}else{
			[PhotoManager getImageHighQualityForAsset:self.asset progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
			} resultHandler:^(UIImage *result, NSDictionary *info, BOOL isDownloadFinined) {
				if (isDownloadFinined) {
					[ws shareWithURL:result];
					[ws.activityIndicator stopAnimating];
				}
			}];
		}
	}
}
-(void)shareWithURL:(id)model {
	NSArray *activityItems = @[model];
	UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
	[self presentViewController:activityController animated:YES completion:nil];
	activityController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
		if (completed) {
			NSLog(@"completed"); //分享 成功
		} else  {
			NSLog(@"cancled"); //分享 取消
		}
	};
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"rate"]) {
		if (self.avPlayer.rate == 0) {
			self.playImgView.hidden = NO;
		}else{
			if ([NSThread currentThread] == [NSThread mainThread]) {
				self.playImgView.hidden = YES;
			}else{
				dispatch_async(dispatch_get_main_queue(), ^{
					self.playImgView.hidden = YES;
				});
			}
		}
	}
}

-(void)onTap:(UITapGestureRecognizer *)tap
{
	if (tap.state ==UIGestureRecognizerStateEnded ) {
		if (self.asset.mediaType == PHAssetMediaTypeVideo) {
			if (self.avPlayer.rate == 0 ) {
				[self.avPlayer  play];
			}else{
				[self.avPlayer  pause];
			}
		}else{
			if (_bgScrollView.zoomScale <= 1.0) {
				[_bgScrollView setZoomScale:2.0f animated:YES];
			}else{
				[_bgScrollView setZoomScale:0.8f animated:YES];
			}
		}
	}
}
-(void)addTimeObserver {
	__weak typeof(self)WeakSelf = self;
	[self removetimeObserVer];
	__weak typeof(self)ws = self;
	_timeObser =[self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.01, NSEC_PER_SEC)
															queue:nil usingBlock:^(CMTime time) {
																CGFloat progress = CMTimeGetSeconds(WeakSelf.avPlayer.currentItem.currentTime) / CMTimeGetSeconds(WeakSelf.avPlayer.currentItem.duration);
																ws.progressView.progress = progress;
															}];
}

-(void)removetimeObserVer
{
	if (_timeObser) {
		[self.avPlayer removeTimeObserver:_timeObser];
		_timeObser = nil;
	}
}
-(void)moviePlayDidEnd:(NSNotification *)noti
{
	[self.avPlayer seekToTime:kCMTimeZero];
	[self.avPlayer play];
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	if (scrollView.zoomScale <= 1.0) {
		self.containtImgView.center = scrollView.center;
	}else{
		CGFloat cX = self.bgScrollView.contentSize.width/2.0;
		CGFloat cY = self.bgScrollView.contentSize.height/2.0;
		self.containtImgView.center = CGPointMake(cX, cY);
	}
}
-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
	if (scale >= 1.0) {
		[self.navigationController setNavigationBarHidden:YES animated:YES];
	}else{
		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
}
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.containtImgView;
}
-(void)dealloc
{
	if (self.asset.mediaType == PHAssetMediaTypeVideo) {
		[self.avPlayer removeObserver:self forKeyPath:@"rate"];
		[[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	}
	[self removetimeObserVer];
}

-(void)creactAndSaveLivePhoto:(NSURL *)url
{
	if ([url isKindOfClass:[NSURL class]]) {
		[LivePhotoMaker makeLivePhotoByLibrary:url completed:^(NSDictionary *resultDic) {
			if (resultDic) {
				NSURL * videoUrl = resultDic[@"MOVPath"];
				NSURL * imageUrl = resultDic[@"JPGPath"];
				if (videoUrl&&imageUrl) {
					[LivePhotoMaker saveLivePhotoToAlbumWithMovPath:videoUrl ImagePath:imageUrl completed:^(BOOL isSuccess) {
						if (isSuccess) {
							NSLog(@"创建成功");
						}
					}];
				}
			}
		}];
	}
}

@end
