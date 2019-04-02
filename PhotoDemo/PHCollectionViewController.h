//
//  PHCollectionViewController.h
//  PhotoDemo
//
//  Created by ios2 on 2019/3/1.
//  Copyright © 2019 ShanZhou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoManager.h"

@interface PHCollectionViewController : UIViewController

@property (nonatomic,strong)PHAssetCollection *assetCollection;

@property (nonatomic,copy)NSString *navTitle;

@property (nonatomic,strong)PHFetchResult *result;

@end





