//
//  CloudPhotoDownloadViewController.m
//  FunSDKDemo
//
//  Created by XM on 2019/1/4.
//  Copyright © 2019年 XM. All rights reserved.
//

#import "CloudPhotoDownloadViewController.h"
#import "ItemTableviewCell.h"

@interface CloudPhotoDownloadViewController ()
<UITableViewDelegate,UITableViewDataSource,CloudPhotoConfigDelegate>
{
    CloudPhotoConfig *config;
    XMAlarmMsgResource *resource;
    UITableView *tableV;
    NSString *thumbPath;
    NSString *picPath;
    float progres;
}
@end

@implementation CloudPhotoDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSubView];
}

#pragma mark - 开始下载设备图片
- (void)startDownloadCloudPicture:(XMAlarmMsgResource*)msgResource {
    resource = msgResource;
    if (config == nil) {
        config = [[CloudPhotoConfig alloc] init];
        config.delegate = self;
    }
    
    if (msgResource.JsonStr == nil) {
        [SVProgressHUD showSuccessWithStatus:@"No Pic" duration:1];
        return;
    }
    
    //下载小缩略图
    [config downloadSmallCloudPicture:resource];
    //下载原图
    [config downloadCloudPicture:resource];
}
#pragma mark -下载图片结果回调
// 下载云存储缩略图
- (void)downloadSmallCloudPictureResult:(int)result path:(NSString*)path {
    if (result < 0) {
        [MessageUI ShowErrorInt:(int)result];
    }else{
        [SVProgressHUD dismiss];
        thumbPath = path;
        [tableV reloadData];
    }
}
#pragma mark -  下载云存储原图回调   云存储下载图片没有进度信息回调，只有结果（速度比设备端下载块）
- (void)downloadCloudPictureResult:(int)result path:(NSString*)path {
    picPath = path;
    [tableV reloadData];
}

#pragma mark - 删除云报警消息
-(void)btnDeleteClicked:(UIButton *)sender{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:TS("TR_Delete_Items_Tip") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:TS("Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:TS("OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [config deleteCloudAlarmMessage:self.alarmID];
    }];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 删除云报警消息回调
-(void)deleteAlarmMessageConfigResult:(NSInteger)result{
    if (result < 0) {
        
    }else{
        if (self.deleteAlarmMessageBlock) {
            self.deleteAlarmMessageBlock(self.selectNum);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - tableView代理方法
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 3) {
        return 300;
    }
    return 60;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ItemTableviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemTableviewCell"];
    if (!cell) {
        cell = [[ItemTableviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ItemTableviewCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    if (indexPath.row == 0) {
        //云图片日期时间
        cell.textLabel.text = resource.startTime;
    }else if (indexPath.row == 1) {
        //云图片缩略图和大小
        cell.textLabel.text = [NSString stringWithFormat:@"fileSize：%dK",resource.size];
        if (thumbPath && thumbPath.length >1) {
            NSData *data = [NSData dataWithContentsOfFile:thumbPath];
            cell.imageView.image = [UIImage imageWithData:data];
        }
    }else if (indexPath.row == 2) {
        //云视频原图下载进度
        cell.textLabel.text = [NSString stringWithFormat:@"DownloadProgress: %04f%@",progres*100,@"%"];
    }else if (indexPath.row == 3) {
        //云视频原图显示
        if (picPath && picPath.length >1) {
            NSData *data = [NSData dataWithContentsOfFile:picPath];
            UIImageView *imageV = [[UIImageView alloc] initWithFrame:CGRectMake(20, 0, 300, 300)];
            imageV.image = [UIImage imageWithData:data];
            [cell addSubview:imageV];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


#pragma mark - 界面和数据初始化
- (void)configSubView {
    self.title = TS("picture_download");
    self.navigationItem.titleView = [[UILabel alloc] initWithTitle:self.title name:NSStringFromClass([self class])];
    [self.view addSubview:self.tableV];
}
- (UITableView *)tableV {
    if (!tableV) {
        tableV = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight ) style:UITableViewStylePlain];
        tableV.delegate = self;
        tableV.dataSource = self;
        [tableV registerClass:[ItemTableviewCell class] forCellReuseIdentifier:@"ItemTableviewCell"];
        // 添加TableViewFooterView
        UIView *tbFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 80)];
        // 删除按钮
        UIButton *btnDelete = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
        btnDelete.center = tbFooterView.center;
        btnDelete.backgroundColor = [UIColor clearColor];
        [btnDelete setTitle:TS("Delete") forState:UIControlStateNormal];
        btnDelete.layer.borderWidth = 1;
        [btnDelete setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btnDelete addTarget:self action:@selector(btnDeleteClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [tbFooterView addSubview:btnDelete];
        tableV.tableFooterView = tbFooterView;
    }
    return tableV;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
