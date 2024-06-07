//
//  DeviceAudioPlayViewController.m
//  FunSDKDemo
//
//  Created by plf on 2024/4/26.
//  Copyright © 2024 plf. All rights reserved.
//

#import "DeviceAudioPlayViewController.h"
#import "DeviceAudioPlayManager.h"
#import <Masonry/Masonry.h>

@interface DeviceAudioPlayViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UITableView *listTB;
@property(nonatomic,strong)NSArray *listArray;
@property (nonatomic,strong) DeviceAudioPlayManager *deviceAudioPlayManager;

@end

@implementation DeviceAudioPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = TS("TR_DeviceAudioPlay");
    self.navigationItem.titleView = [[UILabel alloc] initWithTitle:self.navigationItem.title name:NSStringFromClass([self class])];
    
    [self initData];
    [self creatView];
    [self getData];
}

-(void)initData
{
    self.listArray = @[];
}

-(void)creatView
{
    [self.view addSubview:self.listTB];
    [self.listTB mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}


-(void)getData
{
    __weak typeof(self) weakSelf = self;
    [self.deviceAudioPlayManager requestAudioList:self.devID completion:^(int result, NSArray *list) {
        if (result >= 0) {
            weakSelf.listArray = [NSArray arrayWithArray:list];
            [weakSelf.listTB reloadData];
        }
    }];
}


#pragma mark -- UITableViewDelegate/dataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSDictionary *info = [self.listArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [info objectForKey:@"FileName"];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *info = [self.listArray objectAtIndex:indexPath.row];
    int tag = [[info objectForKey:@"FileNumber"] intValue];
    
    [self.deviceAudioPlayManager playAudioSign:tag device:self.devID completion:^(int result) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (result >= 0) {
                [SVProgressHUD showSuccessWithStatus:TS("EE_AS_LOGIN_CODE0")];
            }else{
                [SVProgressHUD showErrorWithStatus:TS("feedback_send_failed")];
            }
        });
    }];
}





-(UITableView *)listTB
{
    if(!_listTB)
    {
        _listTB = [[UITableView alloc]init];
        _listTB.delegate = self;
        _listTB.dataSource = self;
        [_listTB registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
        _listTB.tableFooterView = [UIView new];
    }
    return _listTB;
}

- (DeviceAudioPlayManager *)deviceAudioPlayManager{
    if (!_deviceAudioPlayManager) {
        _deviceAudioPlayManager = [[DeviceAudioPlayManager alloc] init];
    }
    
    return _deviceAudioPlayManager;
}

@end
