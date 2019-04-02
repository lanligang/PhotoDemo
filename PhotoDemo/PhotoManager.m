//
//  PhotoManager.m
//  ForkingDogDemo
//
//  Created by ios2 on 2019/3/1.
//  Copyright © 2019 LenSky. All rights reserved.
//

#import "PhotoManager.h"

@implementation PhotoManager

+(NSArray <PHAssetCollection *> *)getphotoListDatas {
	NSMutableArray *dataArray = [NSMutableArray array];
		//PHFetchOptions:获取资源时的参数，可以传nil，即使用系统默认值
	PHFetchOptions *fechOptions = [[PHFetchOptions alloc]init];
	// 列出所有相册智能相册
	PHFetchResult *smartAblunmsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:fechOptions];
	for (PHAssetCollection * sub in smartAblunmsFetchResult) {
		if ([sub isKindOfClass:[PHAssetCollection class]]) {
			[dataArray addObject:sub];
		}
	}
	// 列出所有用户创建的相册
	PHFetchResult *smartAlbumsFetchResult1 = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:fechOptions];
	for (PHAssetCollection *sub in smartAlbumsFetchResult1) {
		if ([sub isKindOfClass:[PHAssetCollection class]]) {
			[dataArray addObject:sub];
		}
	}
	return dataArray;
}
	//获取一个相册的结果集(按时间排序)
+(PHFetchResult<PHAsset *>*) getResult:(PHAssetCollection *)assetCollection ascend:(BOOL)ascend
{
	PHFetchOptions *options = [self getFetchPhotosOptions:ascend];
		//NSSortDescriptor 排序规则描述类  https://www.jianshu.com/p/3e9f0884be6b
	/*
	 一种初始化方法 ： 参数 key 要进行排序的key   ascending: 是否升序, YES-升序, NO-降序
	 sortDescriptorWithKey:(nullable NSString *)key ascending:(BOOL)ascending
	 */
		// photokit fetch result
	PHFetchResult *results = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
	return results;
}

/* 获取某个类型的结果集按照时间排序
 * mediaType :   PHAssetMediaTypeImage   = 1,  PHAssetMediaTypeVideo   = 2,  PHAssetMediaTypeAudio   = 3,
 * ascend YES - 升序 NO - 降序
 */
+(PHFetchResult  <PHAsset *>*)getFechResultWithMediaType:(PHAssetMediaType)mediaType ascend:(BOOL)ascend {
	PHFetchOptions * options = [self getFetchPhotosOptions:ascend];
	return  [PHAsset fetchAssetsWithMediaType:mediaType options:options];
}

+(PHFetchOptions *)getFetchPhotosOptions:(BOOL)ascend{
	PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc]init];
		//扫描的范围为：用户相册，iCloud分享，iTunes同步
		if (@available(iOS 9.0,*)) {
				allPhotosOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared | PHAssetSourceTypeiTunesSynced;
		}
	   //排序的方式为：按时间排序
	allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascend]];
	return allPhotosOptions;
}

/* * 获取系统相册 cameraRoll 的结果集 按时间排序
 * ascend YES - 升序 NO - 降序
 */
+(PHFetchResult  <PHAsset *>*)CameraRollFetchResulWithAscend:(BOOL)ascend {
	PHFetchOptions * options = [self getFetchPhotosOptions:ascend];
	PHFetchResult *smartAblumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:options];
	PHFetchResult *fetch = [PHAsset fetchAssetsInAssetCollection:[smartAblumsFetchResult objectAtIndex:0] options:options];
	return fetch;
}

/**  获取单张高清图
 * progressHandler为从iCloud下载进度
 */
+(void)getImageHighQualityForAsset:(PHAsset *)asset
				   progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler
					 resultHandler:(void (^)(UIImage* result, NSDictionary * info,BOOL isDownloadFinined))resultHandler {
	CGSize imageSize = [self imageSizeForAsset:asset];
	PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
	//设置该模式，若本地无高清图会立即返回缩略图，需要从iCloud下载高清，会再次调用resultHandler返回下载后的高清图
	options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
	options.resizeMode = PHImageRequestOptionsResizeModeFast;
	options.networkAccessAllowed = YES;
	options.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
		if (progressHandler) {
			dispatch_async(dispatch_get_main_queue(), ^{
				progressHandler(progress,error,stop,info);
			});
		}
	};
	[[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
			//判断高清图
			   BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
		if (result && resultHandler) {
			resultHandler([self fixOrientation:result],info,downloadFinined);
		}
	}];
}

+(PHImageRequestID)getOriginalPhotoWithAsset:(PHAsset *)asset progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler newCompletion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
	PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
	option.networkAccessAllowed = YES;
	if (progressHandler) {
		[option setProgressHandler:progressHandler];
	}
	option.resizeMode = PHImageRequestOptionsResizeModeFast;
	return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage *result, NSDictionary *info) {
		BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
		if (downloadFinined && result) {
			result = [self fixOrientation:result];
			BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
			if (completion) completion(result,info,isDegraded);
		}
	}];
}
	/// 修正图片转向
+ (UIImage *)fixOrientation:(UIImage *)aImage {
		// No-op if the orientation is already correct
	if (aImage.imageOrientation == UIImageOrientationUp)
		return aImage;
		// We need to calculate the proper transformation to make the image upright.
		// We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
	CGAffineTransform transform = CGAffineTransformIdentity;
	switch (aImage.imageOrientation) {
		case UIImageOrientationDown:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;

		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
			transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
			transform = CGAffineTransformRotate(transform, M_PI_2);
			break;

		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
			transform = CGAffineTransformRotate(transform, -M_PI_2);
			break;
		default:
			break;
	}

	switch (aImage.imageOrientation) {
		case UIImageOrientationUpMirrored:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;

		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
		default:
			break;
	}

		// Now we draw the underlying CGImage into a new context, applying the transform
		// calculated above.
	CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
											 CGImageGetBitsPerComponent(aImage.CGImage), 0,
											 CGImageGetColorSpace(aImage.CGImage),
											 CGImageGetBitmapInfo(aImage.CGImage));
	CGContextConcatCTM(ctx, transform);
	switch (aImage.imageOrientation) {
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
				// Grr...
			CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
			break;

		default:
			CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
			break;
	}

		// And now we just create a new UIImage from the drawing context
	CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
	UIImage *img = [UIImage imageWithCGImage:cgimg];
	CGContextRelease(ctx);
	CGImageRelease(cgimg);
	return img;
}



+(CGSize)imageSizeForAsset:(PHAsset *)asset {
	CGFloat photoWidth = [UIScreen mainScreen].bounds.size.width;
	CGFloat multiple = [UIScreen mainScreen].scale;
	CGFloat aspectRatio = asset.pixelWidth / (CGFloat)asset.pixelHeight;
	CGFloat pixelWidth = photoWidth * multiple;
	CGFloat pixelHeight = pixelWidth / aspectRatio;
	return  CGSizeMake(pixelWidth, pixelHeight);
}

/**获取单张缩略图 */
+(void)getImageLowQualityForAsset:(PHAsset *)asset
					   targetSize:(CGSize)targetSize
					resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler{
	[[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		if (result && resultHandler) {
			resultHandler(result,info);
		}
	}];
}

+(void)getImagesForAssets:(NSArray<PHAsset *> *)assets
		  progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler
			resultHandler:(void (^)(NSArray<NSDictionary *> *))resultHandler{
	NSMutableArray * callBackPhotos = [NSMutableArray array];

		//此处在子线程中执行requestImageForAsset原因：options.synchronous设为同步时,options.progressHandler获取主队列会死锁
	NSOperationQueue * queue = [[NSOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;

	for (PHAsset * asset in assets) {
		CGSize imageSize = [self imageSizeForAsset:asset];
		PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
			//        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
		options.resizeMode = PHImageRequestOptionsResizeModeExact;
		options.networkAccessAllowed = YES;
			//同步保证取出图片顺序和选择的相同，deliveryMode默认为PHImageRequestOptionsDeliveryModeHighQualityFormat
		options.synchronous = YES;

		options.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
			dispatch_async(dispatch_get_main_queue(), ^{
				progressHandler(progress,error,stop,info);
			});
		};

		NSBlockOperation * op = [NSBlockOperation blockOperationWithBlock:^{
			[[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
					//resultHandler默认在主线程，requestImageForAsset在子线程执行后resultHandler变为在子线程
				if (result) {
						//压缩图片，可用于上传
					NSData * data = UIImageJPEGRepresentation(result, 0.7); //[UIImage resetSizeOfImageData:result compressQuality:0.2];
					UIImage * image = [UIImage imageWithData:data];
					NSDictionary * dic = @{@"EEPhotoImage":image,@"EEPhotoName":asset.localIdentifier};
					[callBackPhotos addObject:dic];
					if (resultHandler && callBackPhotos.count == assets.count) {
						dispatch_async(dispatch_get_main_queue(), ^{
							resultHandler(callBackPhotos);
						});
					}
				}
			}];
		}];
		[queue addOperation:op];
	}
}

//系统进行认证
+(void)requestAuthorizationHandler:(void(^)(BOOL isAuthorized))handler {
	if (handler) {
		[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (status == PHAuthorizationStatusAuthorized) {
					handler(YES);
				}else{
					handler(NO);
				}
			});
		}];
	}
}


+ (void)getVideoOutputPathWithAsset:(PHAsset *)asset
						videoQuality:(VideoQualityType)qulityType
							success:(void (^)(NSString *outputPath))success
							failure:(void (^)(NSString *errorMessage, NSError *error))failure {
	PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
	options.version = PHVideoRequestOptionsVersionOriginal;
	options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
	options.networkAccessAllowed = YES;
	[[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
		AVURLAsset *videoAsset = (AVURLAsset*)avasset;
		NSString * presetName =  AVAssetExportPreset640x480;
		switch (qulityType) {
			case SmallVideoQuality:
			presetName =  AVAssetExportPreset640x480;
			break;
			case MiddleVideoQuality:
			presetName =  AVAssetExportPreset960x540;
			break;
			case HieghtVideoQuality:
			presetName =  AVAssetExportPreset1280x720;
			break;
		}
		[self startExportVideoWithVideoAsset:videoAsset presetName:presetName success:success failure:failure];
	}];
}


+(void)startExportVideoWithVideoAsset:(AVURLAsset *)videoAsset presetName:(NSString *)presetName success:(void (^)(NSString *outputPath))success failure:(void (^)(NSString *errorMessage, NSError *error))failure {
		// Find compatible presets by video asset.
	NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
		// Begin to compress video
		// Now we just compress to low resolution if it supports
		// If you need to upload to the server, but server does't support to upload by streaming,
		// You can compress the resolution to lower. Or you can support more higher resolution.
	if ([presets containsObject:presetName]) {
		AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:presetName];
		NSDateFormatter *formater = [[NSDateFormatter alloc] init];
		[formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss-SSS"];
		NSString *outputPath = [NSHomeDirectory() stringByAppendingFormat:@"/tmp/video-%@.mp4", [formater stringFromDate:[NSDate date]]];
		if (videoAsset.URL && videoAsset.URL.lastPathComponent) {
			outputPath = [outputPath stringByReplacingOccurrencesOfString:@".mp4" withString:[NSString stringWithFormat:@"-%@", videoAsset.URL.lastPathComponent]];
		}
			// NSLog(@"video outputPath = %@",outputPath);
		session.outputURL = [NSURL fileURLWithPath:outputPath];

			// Optimize for network use.
		session.shouldOptimizeForNetworkUse = true;

		NSArray *supportedTypeArray = session.supportedFileTypes;
		if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
			session.outputFileType = AVFileTypeMPEG4;
		} else if (supportedTypeArray.count == 0) {
			if (failure) {
				failure(@"该视频类型暂不支持导出", nil);
			}
			NSLog(@"No supported file types 视频类型暂不支持导出");
			return;
		} else {
			session.outputFileType = [supportedTypeArray objectAtIndex:0];
		}

		if (![[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingFormat:@"/tmp"]]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:[NSHomeDirectory() stringByAppendingFormat:@"/tmp"] withIntermediateDirectories:YES attributes:nil error:nil];
		}

			AVMutableVideoComposition *videoComposition = [self fixedCompositionWithAsset:videoAsset];
			if (videoComposition.renderSize.width) {
					// 修正视频转向
				session.videoComposition = videoComposition;
			}

			// Begin to export video to the output path asynchronously.
		[session exportAsynchronouslyWithCompletionHandler:^(void) {
			dispatch_async(dispatch_get_main_queue(), ^{
				switch (session.status) {
					case AVAssetExportSessionStatusUnknown: {
						NSLog(@"AVAssetExportSessionStatusUnknown");
					}  break;
					case AVAssetExportSessionStatusWaiting: {
						NSLog(@"AVAssetExportSessionStatusWaiting");
					}  break;
					case AVAssetExportSessionStatusExporting: {
						NSLog(@"AVAssetExportSessionStatusExporting");
					}  break;
					case AVAssetExportSessionStatusCompleted: {
						NSLog(@"AVAssetExportSessionStatusCompleted");
						if (success) {
							success(outputPath);
						}
					}  break;
					case AVAssetExportSessionStatusFailed: {
						NSLog(@"AVAssetExportSessionStatusFailed");
						if (failure) {
							failure(@"视频导出失败", session.error);
						}
					}  break;
					case AVAssetExportSessionStatusCancelled: {
						NSLog(@"AVAssetExportSessionStatusCancelled");
						if (failure) {
							failure(@"导出任务已被取消", nil);
						}
					}  break;
					default: break;
				}
			});
		}];
	} else {
		if (failure) {
			NSString *errorMessage = [NSString stringWithFormat:@"当前设备不支持该预设:%@", presetName];
			failure(errorMessage, nil);
		}
	}
}
/// 获取优化后的视频转向信息
+ (AVMutableVideoComposition *)fixedCompositionWithAsset:(AVAsset *)videoAsset {
	AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
		// 视频转向
	int degrees = [self degressFromVideoFileWithAsset:videoAsset];
	if (degrees != 0) {
		CGAffineTransform translateToCenter;
		CGAffineTransform mixedTransform;
		videoComposition.frameDuration = CMTimeMake(1, 30);

		NSArray *tracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
		AVAssetTrack *videoTrack = [tracks objectAtIndex:0];

		AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
		AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

		if (degrees == 90) {
				// 顺时针旋转90°
			translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
			mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2);
			videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
			[roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
		} else if(degrees == 180){
				// 顺时针旋转180°
			translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
			mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
			videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
			[roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
		} else if(degrees == 270){
				// 顺时针旋转270°
			translateToCenter = CGAffineTransformMakeTranslation(0.0, videoTrack.naturalSize.width);
			mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2*3.0);
			videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
			[roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
		}

		roateInstruction.layerInstructions = @[roateLayerInstruction];
			// 加入视频方向信息
		videoComposition.instructions = @[roateInstruction];
	}
	return videoComposition;
}
	/// 获取视频角度
+(int)degressFromVideoFileWithAsset:(AVAsset *)asset {
	int degress = 0;
	NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
	if([tracks count] > 0) {
		AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
		CGAffineTransform t = videoTrack.preferredTransform;
		if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
				// Portrait
			degress = 90;
		} else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
				// PortraitUpsideDown
			degress = 270;
		} else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
				// LandscapeRight
			degress = 0;
		} else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
				// LandscapeLeft
			degress = 180;
		}
	}
	return degress;
}
//获取一张GIF图片
+(void)getGifImgData:(PHAsset *)asset andCompletion:(void(^)(NSData *data))completion
{
	NSArray *resourceList = [PHAssetResource assetResourcesForAsset:asset];
	[resourceList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		PHAssetResource *resource = obj;
		PHAssetResourceRequestOptions *option = [[PHAssetResourceRequestOptions alloc]init];
		option.networkAccessAllowed = YES;//是否允许网络下载
		//获取沙盒路径
		 NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
		NSString *imageFilePath = [path stringByAppendingPathComponent:resource.originalFilename];
		 if ([resource.uniformTypeIdentifier isEqualToString:@"com.compuserve.gif"]||[resource.uniformTypeIdentifier isEqualToString:@"public.heic"]) {
			 [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:[NSURL fileURLWithPath:imageFilePath] options:option completionHandler:^(NSError * _Nullable error) {
				 if (error == nil) {
					 NSData *data = [NSData dataWithContentsOfFile:imageFilePath];
					 if (completion) {
						 completion(data);
					 }
				 }else{
					 if (completion) {
						 completion(nil);
					 }
				 }
				 [[NSFileManager defaultManager]removeItemAtPath:imageFilePath error:nil];
			 }];
		 }
	}];
}
@end
