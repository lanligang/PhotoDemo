//
//  ViewController.m
//  PhotoDemo
//
//  Created by ios2 on 2019/3/1.
//  Copyright © 2019 ShanZhou. All rights reserved.
//

#import "ViewController.h"
#import "PhotoManager.h"
#import "PHCollectionViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)NSMutableArray *dataSource;
@property (nonatomic,strong)UITableView *myTableView;
@property (nonatomic,strong)NSMutableDictionary *countDic;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.title = @"相册";
	[self.view addSubview:self.myTableView];
	[self.myTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
	 [self.myTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell2"];
	self.myTableView.frame = self.view.bounds;
	self.myTableView.delegate = self;
	self.myTableView.dataSource = self;
	[self loadDataSource];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(countDidChange:) name:@"countDidChanged" object:nil];
}
-(void)countDidChange:(NSNotification *)noti
{
	NSDictionary *dic = (NSDictionary *)noti.object;
	[self.countDic setObject:dic.allValues.firstObject forKey:dic.allKeys.firstObject];
	[self.myTableView reloadData];
}
-(void)loadDataSource
{
	[PhotoManager requestAuthorizationHandler:^(BOOL isAuthorized) {
		if (isAuthorized) {
			NSArray *result = [PhotoManager getphotoListDatas];
			for (PHAssetCollection *aseetCollection in result) {
				// 有可能是PHCollectionList类的的对象，过滤掉
				 if (![aseetCollection isKindOfClass:[PHAssetCollection class]]) continue;
				if (aseetCollection.estimatedAssetCount <= 0) continue;
				[self.dataSource addObject:aseetCollection];
			}
			[self.myTableView reloadData];
			[self tableView:self.myTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		}else{
		}
	}];
}
-(NSMutableDictionary *)countDic
{
	if (!_countDic)
	 {
		_countDic = [[NSMutableDictionary alloc]init];
	 }
	return _countDic;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return self.dataSource.count;
	}else{
		return 2;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		UITableViewCell *cell = nil;
		cell =  [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		PHAssetCollection *assetCollection = self.dataSource[indexPath.row];
		if (assetCollection.estimatedAssetCount == NSNotFound) {
			NSString *str = [NSString stringWithFormat:@"%@     %@",assetCollection.localizedTitle,self.countDic[assetCollection.localizedTitle]];
			cell.textLabel.text = str;
		}else{
			NSString *str = [NSString stringWithFormat:@"%@     %lu",assetCollection.localizedTitle,(unsigned long)((assetCollection.estimatedAssetCount == NSNotFound)?0:assetCollection.estimatedAssetCount) ];
			cell.textLabel.text = str;
		}
		return cell;
	}else{
		UITableViewCell *cell = nil;
		cell =  [tableView dequeueReusableCellWithIdentifier:@"cell2" forIndexPath:indexPath];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		cell.textLabel.text = (indexPath.row == 0)? @"图片":@"视频";
		return cell;
	}
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		PHCollectionViewController *vc = [[PHCollectionViewController alloc]init];
		vc.assetCollection = self.dataSource[indexPath.row];
		[self.navigationController pushViewController:vc animated:YES];
	}else{
		//获取某种类型的数据
		PHCollectionViewController *vc = [[PHCollectionViewController alloc]init];
		PHFetchResult *result =  [PhotoManager getFechResultWithMediaType:(indexPath.row == 0)?PHAssetMediaTypeImage:PHAssetMediaTypeVideo ascend:YES];
		vc.navTitle = (indexPath.row == 0) ? @"图片":@"视频";
		vc.result = result;
		[self.navigationController pushViewController:vc animated:YES];
	}
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 20;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	   return CGFLOAT_MIN;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	return nil;
}

-(NSMutableArray *)dataSource
{
	if (!_dataSource)
	 {
		_dataSource = [[NSMutableArray alloc]init];
	 }
	return _dataSource;
}
-(UITableView *)myTableView
{
	if (!_myTableView)
	 {
		_myTableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
	 }
	return _myTableView;
}

@end
