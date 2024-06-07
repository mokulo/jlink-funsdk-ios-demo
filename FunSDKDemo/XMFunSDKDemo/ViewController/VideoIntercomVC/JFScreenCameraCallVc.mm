//
//  JFScreenCameraCallVc.m
//   iCSee
//
//  Created by kevin on 2023/11/25.
//  Copyright © 2023 xiongmaitech. All rights reserved.
//

#import "JFScreenCameraCallVc.h"
#import "VideoIntercomVC.h"
#import "AppDelegate.h"
#import "DeviceObject.h"
#import "JFHangUpPopView.h"
#import <XMNetInterface/Reachability.h>
@interface JFScreenCameraCallVc ()<UINavigationControllerDelegate,vcDismissDelegate>
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *lblDevice;
@property (nonatomic, strong) UILabel *lblTips;
@property (nonatomic, strong) UIButton *btnCameraFlip;//前置后置切换
@property (nonatomic, strong) UIButton *btnCameraShow;//摄像头打开关闭

@property (nonatomic, strong) UILabel *lblCameraFlip;//前置后置切换
@property (nonatomic, strong) UILabel *lblCameraShow;//摄像头打开关闭
@property (nonatomic, strong) UIButton *btnHangUp;// 挂断
@property (nonatomic, strong) UIButton *btnAnswer;//接听

@property (nonatomic,assign) BOOL isCloseCamera;
@property (nonatomic,assign) BOOL isBackGroundCamera;
@property (nonatomic, strong) JFHangUpPopView *hangUpPopView;//已挂断弹窗


@end

@implementation JFScreenCameraCallVc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
     
    self.isCloseCamera = [[NSUserDefaults standardUserDefaults] boolForKey: KEY_ISScreenVideoCloseCamera];
    self.isBackGroundCamera = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_ISScreenVideoBackGroundCamera];
    [self buildUI];
    [self setupHangUpPopView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraHangUpAction:) name:@"CameraHangUp" object:nil];

    [self startHangUpTime];
    // Do any additional setup after loading the view.
}

- (void)setupHangUpPopView {
    [self.view addSubview:self.hangUpPopView];
    self.hangUpPopView.hidden = YES;
    [self.hangUpPopView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_lessThanOrEqualTo(SCREEN_WIDTH - 50);
        make.center.equalTo(self.view);
    }];
}
- (void)buildUI {
    self.view.backgroundColor = [UIColor blackColor];
    self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
     
    self.bgView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.bgView];
    
    DeviceObject *device = [[DeviceControl getInstance] GetDeviceObjectBySN: self.devID];
    self.lblDevice = [[UILabel alloc] init];
    self.lblDevice.textColor = [UIColor whiteColor];
    self.lblDevice.font = [UIFont systemFontOfSize:20];
    self.lblDevice.textAlignment = NSTextAlignmentCenter;
    self.lblDevice.numberOfLines = 0;
    self.lblDevice.text = device.deviceName;
    [self.view addSubview: self.lblDevice];
    [self.lblDevice mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(55);
    }];
    
    self.lblTips = [[UILabel alloc] init];
    self.lblTips.textColor = [UIColor whiteColor];
    self.lblTips.font = [UIFont systemFontOfSize:16];
    self.lblTips.textAlignment = NSTextAlignmentCenter;
    self.lblTips.numberOfLines = 0;
    self.lblTips.text = TS("TR_inviteVideoCall");
    [self.view addSubview: self.lblTips];
    [self.lblTips mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.lblDevice.mas_bottom).mas_offset(5);
    }];
    
    self.btnHangUp = [[UIButton alloc] init];
    [self.btnHangUp setTitle: @"挂断" forState:UIControlStateNormal];
    [self.btnHangUp addTarget:self action:@selector(hangUpAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnHangUp];
    [self.btnHangUp mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(50);
        make.bottom.mas_equalTo(-79);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    self.btnAnswer = [[UIButton alloc] init];
    [self.btnAnswer setTitle: @"接听" forState:UIControlStateNormal];
    [self.btnAnswer addTarget:self action:@selector(answerAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnAnswer];
    [self.btnAnswer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-50);
        make.bottom.mas_equalTo(-79);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    self.btnCameraFlip = [[UIButton alloc] init];
    [self.btnCameraFlip setTitle: @"摄像头" forState:UIControlStateNormal];
    self.btnCameraFlip.selected = self.isBackGroundCamera;
    [self.btnCameraFlip addTarget:self action:@selector(CameraFlipAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnCameraFlip];
    [self.btnCameraFlip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(50);
        make.bottom.mas_equalTo(self.btnHangUp.mas_top).mas_offset(-30);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    self.lblCameraFlip = [[UILabel alloc] init];
    self.lblCameraFlip.font = [UIFont systemFontOfSize:12];
    self.lblCameraFlip.textColor = [UIColor whiteColor];
    self.lblCameraFlip.numberOfLines = 0;
    self.lblCameraFlip.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.lblCameraFlip];
    [self.lblCameraFlip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.btnCameraFlip.mas_centerX);
        make.top.mas_equalTo(self.btnCameraFlip.mas_bottom).mas_offset(-20);
        make.width.mas_lessThanOrEqualTo(120);
    }];
    
    if (self.isBackGroundCamera) {
        self.lblCameraFlip.text = TS("TR_BackGround_camera");
    } else {
        self.lblCameraFlip.text = TS("TR_Front_camera");
    }
    
    
    self.btnCameraShow = [[UIButton alloc] init];
    [self.btnCameraShow setImage:[UIImage imageNamed:@"ic_call_lens_open"] forState:UIControlStateNormal];
    [self.btnCameraShow setImage:[UIImage imageNamed:@"ic_call_lens_close"] forState:UIControlStateSelected];

    self.btnCameraShow.selected = self.isCloseCamera;
    
    [self.btnCameraShow addTarget:self action:@selector(CameraShowAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnCameraShow];
    [self.btnCameraShow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-50);
        make.bottom.mas_equalTo(self.btnAnswer.mas_top).mas_offset(-30);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    self.lblCameraShow = [[UILabel alloc] init];
    self.lblCameraShow.font = [UIFont systemFontOfSize:12];
    self.lblCameraShow.textColor = [UIColor whiteColor];
    self.lblCameraShow.numberOfLines = 0;
    self.lblCameraShow.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.lblCameraShow];
    [self.lblCameraShow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.btnCameraShow.mas_centerX);
        make.top.mas_equalTo(self.btnCameraShow.mas_bottom).mas_offset(-20);
        make.width.mas_lessThanOrEqualTo(120);
    }];
    if (self.isCloseCamera) {
        self.lblCameraShow.text = TS("TR_CloseCamera");
    } else {
        self.lblCameraShow.text = TS("TR_OpenCamera");
    }
    
}

#pragma mark - **************** action ****************

//30秒未接听自动挂断
- (void)startHangUpTime {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOuthangUpAction) object:nil];
    [self performSelector:@selector(timeOuthangUpAction) withObject:nil afterDelay:30];
}
- (void)timeOuthangUpAction {
    [self hangUpMassageNitofi];
}
- (void)cameraHangUpAction:(NSNotification *)notification {
    NSDictionary *dicInfo = [notification userInfo];
    NSString *devID  = [dicInfo objectForKey:@"UUID"];
    // 不是当前通话设备的挂断推送不处理
    if (![devID isEqualToString:self.devID]) {
        return;
    }  
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOuthangUpAction) object:nil];
    [self hangUpMassageNitofi];
}
- (void)hangUpMassageNitofi {
    [self.hangUpPopView showWithTime:@"calloff"];
    self.hangUpPopView.hidden = NO;
    CGSize parentSize = [ self.hangUpPopView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    if (parentSize.width < 200) {
        parentSize.width = 200;
    }
    // 更新父控件的约束
    [ self.hangUpPopView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(parentSize); // 
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.hangUpPopView removeFromSuperview];
        [self hangUpAction];
    });
}
- (void)hangUpAction {
    if (self.clickbuttonBlock) {
        self.clickbuttonBlock();
    }
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOuthangUpAction) object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)answerAction {
    if (self.clickbuttonBlock) {
        self.clickbuttonBlock();
    }
    if ([self getCurrentNetWorkStatus] == NotReachable) {
        [SVProgressHUD showErrorWithStatus:TS("TR_Error_Network_Error_Try_Later")];
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOuthangUpAction) object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        
        [self dismissViewControllerAnimated:NO completion:^{
            [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOuthangUpAction) object:nil];
            VideoIntercomVC *xmller = [[VideoIntercomVC alloc]init];

            xmller.devID = self.devID;
            xmller.isFromWaitForAnswer = YES;
            xmller.isBackGroundCamera = self.isBackGroundCamera;
            xmller.isCloseCamera = self.isCloseCamera;
            xmller.modalPresentationStyle = UIModalPresentationFullScreen;
            [[UIViewController xm_currentViewController] presentViewController:xmller animated:YES completion:nil];
        }];
    }
    
    
}
- (void)vcDidDismiss {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOuthangUpAction) object:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}
- (void)CameraFlipAction {
    if (self.isBackGroundCamera) {
        self.isBackGroundCamera = NO;
    } else {
        self.isBackGroundCamera = YES;

    }
    [[NSUserDefaults standardUserDefaults] setBool :self.isBackGroundCamera forKey:KEY_ISScreenVideoBackGroundCamera];
    self.btnCameraFlip.selected = self.isBackGroundCamera;
    if (self.isBackGroundCamera) {
        self.lblCameraFlip.text = TS("TR_BackGround_camera");
    } else {
        self.lblCameraFlip.text = TS("TR_Front_camera");
    }
    
}
- (void)CameraShowAction {
    if (self.isCloseCamera) {
        self.isCloseCamera = NO;
    } else {
        self.isCloseCamera = YES;

    }
    [[NSUserDefaults standardUserDefaults] setBool:self.isCloseCamera forKey:KEY_ISScreenVideoCloseCamera];
    self.btnCameraShow.selected = self.isCloseCamera;
    if (self.isCloseCamera) {
        self.lblCameraShow.text = TS("TR_CloseCamera");
    } else {
        self.lblCameraShow.text = TS("TR_OpenCamera");
    }
    
}
-(void)markDeviceRead:(NSString *)devID messageID:(NSString *)messageID
{
    NSMutableDictionary *dic = [self getAlarmStateDic];
    
    NSMutableDictionary *dicChange = [[dic objectForKey:devID] mutableCopy];
    if (!dicChange) {
        dicChange = [NSMutableDictionary dictionaryWithCapacity:0];
        
    }
    [dicChange setObject:@1 forKey:messageID];
    
    [dic setObject:dicChange forKey:devID];
    
    [dic writeToFile:[self getAlarmStateDicPath] atomically:YES];
}

#pragma mark - 获取当前网络标志
-(NetworkStatus)getCurrentNetWorkStatus
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reach currentReachabilityStatus];
    
    return internetStatus;
}
#pragma mark - **************** lazyload ****************

-(NSMutableDictionary *)getAlarmStateDic
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:[self getAlarmStateDicPath]];
    
    if (!dic) {
        dic = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return dic;
}

-(NSString *)getAlarmStateDicPath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    return [path stringByAppendingString:@"/VideoTalkAlarmMsgState.plist"];
}

- (JFHangUpPopView *)hangUpPopView {
    if (!_hangUpPopView) {
        _hangUpPopView = [[JFHangUpPopView alloc] init];
        
    }
    return _hangUpPopView;
}
@end
