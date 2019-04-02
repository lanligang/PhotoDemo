//
//  PhotoBrowViewController.h
//  PhotoDemo
//
//  Created by ios2 on 2019/3/1.
//  Copyright © 2019 ShanZhou. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoManager.h"

@interface PhotoBrowViewController : UIViewController
//图片的所有数据源
@property (nonatomic,strong)PHAsset *asset;
//缩略图
@property (nonatomic,strong)UIImage *smallImg;

@end
