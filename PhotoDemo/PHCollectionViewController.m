//
//  PHCollectionViewController.m
//  PhotoDemo
//
//  Created by ios2 on 2019/3/1.
//  Copyright © 2019 ShanZhou. All rights reserved.
//

#import "PHCollectionViewController.h"
#import "PhotoBrowViewController.h"

@interface PHCollectionViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic,strong)UICollectionView *myCollectionView;
@property (nonatomic,strong)NSMutableArray *dataSource;
@end
@implementation PHCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
	flowLayout.minimumLineSpacing = CGFLOAT_MIN;
	flowLayout.minimumInteritemSpacing = CGFLOAT_MIN;
	CGFloat itemWidth = CGRectGetWidth(UIScreen.mainScreen.bounds)/4 - 1.0;
	flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
	self.myCollectionView = [[UICollectionView alloc]initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
	self.myCollectionView.backgroundColor = [UIColor whiteColor];
	self.myCollectionView.alwaysBounceVertical = YES;
	self.myCollectionView.delegate = self;
	self.myCollectionView.dataSource = self;
	[self.myCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
	[self.view addSubview:self.myCollectionView];
	[self loadDataSource];
	if (self.assetCollection) {
		self.navigationItem.title = self.assetCollection.localizedTitle;
	}else{
		self.navigationItem.title = self.navTitle;
	}
}
-(void)loadDataSource
{
	PHFetchResult *result = (self.result != nil)?self.result:[PhotoManager getResult:self.assetCollection ascend:NO];
	for (PHAsset *asset in result) {
		if (asset) {
			[self.dataSource addObject:asset];
		}
	}
	[self.myCollectionView reloadData];
	if (!self.result) {
			[[NSNotificationCenter defaultCenter]postNotificationName:@"countDidChanged" object:@{self.assetCollection.localizedTitle:@(self.dataSource.count)}];
	}
}
	
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.dataSource.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
	cell.backgroundColor = [UIColor whiteColor];

	UIImageView *imgV =  [cell.contentView viewWithTag:100];
	if (imgV == nil) {
		UIImageView *img = [UIImageView new];
		img.contentMode  = UIViewContentModeScaleAspectFill;
		[cell.contentView addSubview:img];
		img.tag = 100;
		img.layer.masksToBounds = YES;
		imgV = img;
		UIImageView *playImgV = [[UIImageView alloc]init];
		playImgV.tag = 1024;
		[cell.contentView addSubview:playImgV];
		playImgV.image = [UIImage imageNamed:@"player"];
		playImgV.contentMode = UIViewContentModeScaleAspectFit;
		playImgV.frame  = CGRectMake(0, 0, 40, 40);
		playImgV.center = CGPointMake(CGRectGetWidth(cell.bounds)/2.0, CGRectGetHeight(cell.bounds)/2.0);
		UILabel *typeLable = [UILabel new];
		typeLable.backgroundColor  = [[UIColor blackColor]colorWithAlphaComponent:0.5];
		typeLable.layer.cornerRadius = 5.0;
		typeLable.tag = 1001;
		typeLable.layer.masksToBounds = YES;
		typeLable.textColor = [UIColor whiteColor];
		typeLable.textAlignment = NSTextAlignmentCenter;
		[cell.contentView addSubview:typeLable];
	}
	imgV.frame = cell.bounds;
	UILabel * typeLable = (UILabel *)[cell.contentView viewWithTag:1001];
	typeLable.frame = CGRectMake(CGRectGetWidth(cell.bounds) - 35.0, CGRectGetHeight(cell.bounds) - 25.0, 30, 20);
	typeLable.hidden = YES;
	 PHAsset *asset = self.dataSource[indexPath.row];
	UIImageView * plyerImgV = [cell.contentView viewWithTag:1024];
	if (asset.mediaType == PHAssetMediaTypeImage ) {
		//图片
		plyerImgV.hidden = YES;
		NSString *fileName = [asset valueForKey:@"filename"];
		if ([fileName hasSuffix:@"GIF"]) {
			typeLable.text = @"GIF";
			typeLable.hidden = NO;
		}
	}else if (asset.mediaType == PHAssetMediaTypeVideo){
		//视频
		plyerImgV.hidden = NO;
	}
	[PhotoManager getImageLowQualityForAsset:asset targetSize:CGSizeMake(300, 300) resultHandler:^(UIImage *result, NSDictionary *info) {
		imgV.image = result;
	}];
	return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	
	PHAsset *asset = self.dataSource[indexPath.row];
	NSString *filename =  [asset valueForKey:@"filename"];
	NSLog(@"输出文件名:|%@",filename);
	PhotoBrowViewController *brow = [[PhotoBrowViewController alloc]init];
	UIImageView *imgV = (UIImageView *)[[collectionView cellForItemAtIndexPath:indexPath] viewWithTag:100];
	brow.smallImg = imgV.image;
	brow.asset = asset;
	[self.navigationController pushViewController:brow animated:YES];
}

-(NSMutableArray *)dataSource
{
	if (!_dataSource) {
		_dataSource = [[NSMutableArray alloc]init];
	 }
	return _dataSource;
}
@end
