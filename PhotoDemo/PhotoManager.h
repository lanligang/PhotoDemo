//
//  PhotoManager.h
//  ForkingDogDemo
//
//  Created by ios2 on 2019/3/1.
//  Copyright © 2019 LenSky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>


typedef enum : NSUInteger {
	SmallVideoQuality,
	MiddleVideoQuality,
	HieghtVideoQuality,
} VideoQualityType;

@interface PhotoManager : NSObject
// 获取全部相册 集
+(NSArray <PHAssetCollection *> *)getphotoListDatas;

//获取一个相册的结果集(按时间排序)
+(PHFetchResult<PHAsset *>*) getResult:(PHAssetCollection *)assetCollection ascend:(BOOL)ascend;

/* 获取某个类型的结果集按照时间排序
 * mediaType :
                      PHAssetMediaTypeImage   = 1,
					  PHAssetMediaTypeVideo   = 2,
                      PHAssetMediaTypeAudio   = 3,
 * ascend YES - 升序 NO - 降序
 */
+(PHFetchResult  <PHAsset *>*)getFechResultWithMediaType:(PHAssetMediaType)mediaType ascend:(BOOL)ascend;

/* * 获取系统相册 cameraRoll 的结果集 按时间排序
 * ascend YES - 升序 NO - 降序
 */
+(PHFetchResult  <PHAsset *>*)CameraRollFetchResulWithAscend:(BOOL)ascend;

/**  获取单张高清图
 * progressHandler为从iCloud下载进度
 */

+(void)getImageHighQualityForAsset:(PHAsset *)asset
				   progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler
					 resultHandler:(void (^)(UIImage* result, NSDictionary * info,BOOL isDownloadFinined))resultHandler;

//获取原始图片 占用内存很大 -------
+(PHImageRequestID)getOriginalPhotoWithAsset:(PHAsset *)asset
							 progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler newCompletion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;
/**获取单张缩略图 */
+(void)getImageLowQualityForAsset:(PHAsset *)asset
					   targetSize:(CGSize)targetSize
					resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler;

/* 同时获取多张图片(高清)，全部为高清图resultHandler才执行，
 需要从iCloud下载时progressHandler提供每张进度
 */
+(void)getImagesForAssets:(NSArray<PHAsset *> *)assets
		  progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler
			resultHandler:(void (^)(NSArray<NSDictionary *> *))resultHandler;

/* 通过PHAsset 获取视频文件
 * VideoQualityType qulityType 代表了
  * AVAssetExportPreset640x480 , AVAssetExportPreset960x540 ,AVAssetExportPreset1280x720
 */

+ (void)getVideoOutputPathWithAsset:(PHAsset *)asset
						 videoQuality:(VideoQualityType)qulityType
							success:(void (^)(NSString *outputPath))success
							failure:(void (^)(NSString *errorMessage, NSError *error))failure;

/** 相册认证请求
 */
+(void)requestAuthorizationHandler:(void(^)(BOOL isAuthorized))handler;

//获取相册的GIF 的二进制 数据如果失败就是 nil
+(void)getGifImgData:(PHAsset *)asset andCompletion:(void(^)(NSData *data))completion;

@end
