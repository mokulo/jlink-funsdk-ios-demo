//
//  VideoIntercomVC.m
//  FunSDKDemo
//  视频对讲
//  Created by feimy on 2024/5/15.
//

#import "VideoIntercomVC.h"
#import "VideoIntercomView.h"
#import <FunSDK/FunSDK.h>
#import "DoorBellModel.h"
#import "VideoIntercomManager.h"
#import "NSString+Utils.h"
#import "JFHangUpPopView.h"
#import "MediaplayerControl.h"
#import "PlayView.h"

@interface VideoIntercomVC ()<UINavigationControllerDelegate,MediaplayerControlDelegate,UIGestureRecognizerDelegate, PlayViewDelegate>
@property (nonatomic,assign) int msgHandle;
@property(nonatomic,strong) VideoIntercomView *videoView;
@property(nonatomic,assign) BOOL phoneShotIsOpen;//手机摄像头是否打开
@property(nonatomic,assign) BOOL microphoneAuthorizationIsOpen;//麦克风权限是否打开
@property(nonatomic,assign) BOOL cameraAuthorizationIsOpen;//相机权限是否打开
@property (nonatomic, strong) UIView *cameraView;//背景色
@property (nonatomic, strong) PlayView *playView; //播放窗口
@property (nonatomic, strong) MediaplayerControl *mediaPlayer;
@property (nonatomic, strong) NSMutableArray *playViewArray;  //播放画面数组

@property (nonatomic, strong) NSMutableDictionary *devInfoDic;//设备信息

@property (nonatomic, assign) BOOL isFirst;//判断是否是第一次进预览，如果是第一次不需要重新获取状态

@property (nonatomic,strong) NSTimer *timer;//视频对讲计时器
@property (nonatomic,assign) int secNum;//视频对讲持续秒数
@property (nonatomic,strong) VideoIntercomManager *videoIntercomManager;

@property (nonatomic, strong) JFHangUpPopView *hangUpPopView;//已挂断弹窗
@property (nonatomic, assign) BOOL firstIn;//是否是首次进入 首次进入需要判断权限 结束后符合要求会打开视频

@end

@implementation VideoIntercomVC
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    FUN_UnRegWnd(self.msgHandle);
    self.msgHandle = -1;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.msgHandle = FUN_RegWnd((__bridge void*)self);
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    self.focusdevID = self.devID;
    [self.arrayDevIds addObject:self.focusdevID];
    //播放数组
    [self.playViewArray addObject: self.playView];
    self.phoneShotIsOpen = NO;
    self.isFirst = YES;
    self.firstIn = YES;
    //主界面
    [self.view addSubview:self.cameraView];
    self.cameraView.backgroundColor = [UIColor blackColor];
    self.playView.backgroundColor = [UIColor blackColor];
    //播放界面布局
    [self.cameraView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.height.equalTo(self.view.mas_height);
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
    }];
    
    [self.cameraView addSubview:self.playView];
    [self.playView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.cameraView.mas_width);
        make.height.mas_equalTo(realPlayViewHeight);
        make.left.equalTo(self.cameraView);
        make.centerY.equalTo(self).mas_offset(@25);
    }];

    //摄像头及相关按钮
    [self.view addSubview:self.videoView];
    
    NSString *devID = self.focusdevID;
    DeviceObject *devInfo = [[DeviceControl getInstance] GetDeviceObjectBySN: self.focusdevID];
    if(!_devInfoDic) {
        _devInfoDic = [[NSMutableDictionary alloc] initWithCapacity:1];
    }

    [_devInfoDic setObject:devInfo forKey:devInfo.deviceMac];
    self.videoView.deviceNameLab.text = devInfo.deviceName;
    //根据设备信息配置界面 （单通道）
    for (int i = 0; i < self.arrayDevIds.count; i ++) {
        DeviceObject *devInfo = self.devInfoDic[self.arrayDevIds[i]];
        self.mediaPlayer.devID = devInfo.deviceMac;
        self.mediaPlayer.channel = 0;//当前通道号
        self.mediaPlayer.stream = 1;//辅码流
        self.mediaPlayer.renderWnd = [self.playViewArray objectAtIndex:0];
        self.mediaPlayer.type = MediaPlayerTypeRealPlay;
    }
    
    [self setupHangUpPopView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hangUpMassageNitofi:) name:@"JUMPSignUpNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartPlay) name:@"ReStartPlay" object:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.firstIn) {
        self.firstIn = NO;
        //判断麦克风和相机权限后再去开启预览
        if([self checkCameraAbilityNeedTip] && [self checkMicrophoneAbilityNeedTip]){
            //带瓶摇头机预览画面
            [self startPlay: self.mediaPlayer index: 0];
            //视频对讲初始化
            [self.videoIntercomManager initVideoIntercom];
        }else{
            [SVProgressHUD showErrorWithStatus: @"麦克风或相机权限未开"];
        }
    }
}

- (void)setupHangUpPopView {
    [self.view addSubview:self.hangUpPopView];
    self.hangUpPopView.hidden = YES;
    [self.hangUpPopView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.size.mas_equalTo(CGSizeMake(200, 55));
        make.width.mas_lessThanOrEqualTo(SCREEN_WIDTH - 50);
        
        make.center.equalTo(self.view);
    }];
}
- (void)hangUpMassageNitofi:(NSNotification *)notification {
    NSDictionary *dicInfo = [notification userInfo];
    NSString *devID  = [dicInfo objectForKey:@"UUID"];
    // 不是当前通话设备的挂断推送不处理
    if (![devID isEqualToString:self.devID]) {
        return;
    }
    if(self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
    [self.hangUpPopView showWithTime:[self timeFormatted:self.secNum]];
    self.hangUpPopView.hidden = NO;
    CGSize parentSize = [ self.hangUpPopView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    if (parentSize.width < 200) {
        parentSize.width = 200;
    }
    // 更新父控件的约束
    [ self.hangUpPopView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(parentSize); // 父控件的大小等于计算出的大小
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.hangUpPopView removeFromSuperview];
        [self leftBtnClicked];
    });
}

//后台切到前台 重新播放
- (void)restartPlay {
    [self ReStartPlay];
    if (self.mediaPlayer) {
        if (self.videoView.audioBtn.selected == NO) {
            [self.mediaPlayer closeSound];
        } else {
            [self.mediaPlayer openSound:100];
        }
    }
}


#pragma mark - 导航栏按钮点击方法
-(void)leftBtnClicked {
    if(self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }

    if (self.isFromWaitForAnswer) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    if(self.isFirst){
        self.isFirst = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self stopAllRealPlayer];   //终止预览
    [self.videoIntercomManager stopVideoIntercom]; //终止视频对讲(音频和视频)
    FUN_DevLogout(self.msgHandle, [self.focusdevID UTF8String]);//所有设备作退出登录操作
}

#pragma mark - 开始预览
-(void)startPlay:(MediaplayerControl *)mediaViewController index:(NSInteger )index{
    //开启预览
    [self.mediaPlayer start];
    
}

#pragma mark 停止预览
-(void)stopAllRealPlayer{
    for (int i=0; i<self.arrayDevIds.count; i++) {
        NSString *devID = self.arrayDevIds[i];
        if(devID.length <= 0){
            continue;
        }
        if (self.mediaPlayer) {
            [self.mediaPlayer stop];
            [self.mediaPlayer closeSound];
            
            if(devID.length > 0){
                DeviceObject *dev = [[DeviceControl getInstance] GetDeviceObjectBySN:devID];
                if(dev != nil){
                    FUN_DevSleep(self.msgHandle, [devID UTF8String], 0);

                }
            }
        }
    }
}

#pragma mark 重新预览
-(void)ReStartPlay {
    //开启预览
    [self startPlay:self.mediaPlayer index:0];
}

-(void)PlayViewSelected:(int)tag {
   
}

#pragma mark 鱼眼codec配置
- (void)mediaId:(NSString *)devID codecType:(int)codec scene:(int)scene{
    return;
}



#pragma mark - 手机镜头切换
-(void)phoneShotChange{
    if(self.phoneShotIsOpen){
        
        if ([self.videoIntercomManager getCurrentDevicePosition] == 0) {
            [self.videoIntercomManager changeAVCaptureDevicePosition:YES];
            [self.videoView refeshPhoneShotChangeBtnState:YES];
            self.isBackGroundCamera = YES;
        } else {
            [self.videoIntercomManager changeAVCaptureDevicePosition:NO];
            [self.videoView refeshPhoneShotChangeBtnState:NO];
            self.isBackGroundCamera = NO;
        }
        [[NSUserDefaults standardUserDefaults] setBool:self.isBackGroundCamera forKey:KEY_ISScreenVideoBackGroundCamera];
    }else{
 
        [self.videoIntercomManager startCamera];
        [self.videoView refeshPhoneShotBtnState:YES];
        self.phoneShotIsOpen = YES;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:KEY_ISScreenVideoCloseCamera];
        if (!self.isBackGroundCamera) {
            [self.videoIntercomManager changeAVCaptureDevicePosition:YES];
            [self.videoView refeshPhoneShotChangeBtnState:YES];
            self.isBackGroundCamera = YES;
        } else {
            [self.videoIntercomManager changeAVCaptureDevicePosition:NO];
            [self.videoView refeshPhoneShotChangeBtnState:NO];
            self.isBackGroundCamera = NO;
        }
        [[NSUserDefaults standardUserDefaults] setBool:self.isBackGroundCamera forKey:KEY_ISScreenVideoBackGroundCamera];
    }
}

#pragma mark - 挂断电话
-(void)hangUp{
    [self leftBtnClicked];
}

#pragma mark - 扬声器开关
-(void)audioAction{
    [self.videoView refeshAudioBtnState:!self.videoView.audioBtn.selected];
    if (self.mediaPlayer) {
        if (self.videoView.audioBtn.selected == NO) {
            [self.mediaPlayer closeSound];
        } else {
            [self.mediaPlayer openSound:100];
        }
    }
}

#pragma mark - 麦克风开关
-(void)microphoneAction{
    self.microphoneAuthorizationIsOpen = [self checkMicrophoneAbilityNeedTip];
    if(!self.microphoneAuthorizationIsOpen){
        return;
    }
    [self.videoView refeshMicroPhoneBtnState:!self.videoView.microphoneBtn.selected];
    if(self.videoView.microphoneBtn.selected){
        [self.videoIntercomManager startRecord];
    }else{
        [self.videoIntercomManager stopRecord];
    }
}

#pragma mark - 手机镜头开关
-(void)phoneShotAction{
    self.cameraAuthorizationIsOpen = [self checkCameraAbilityNeedTip];
    if(!self.cameraAuthorizationIsOpen){
        return;
    }
    if(self.phoneShotIsOpen){
        self.phoneShotIsOpen = NO;
        [self.videoView refeshPhoneShotBtnState:NO];
        [self.videoIntercomManager stopCamera];
        [self.videoIntercomManager clearVideoImage];
        [self.videoIntercomManager devControlAVTalk:DevControlAVCommandPause retryNum:2];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KEY_ISScreenVideoCloseCamera];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_ISScreenVideoBackGroundCamera]) {
            [self.videoView refeshPhoneShotChangeBtnState:YES];
            [self.videoIntercomManager changeAVCaptureDevicePosition:YES];
        } else {
            [self.videoView refeshPhoneShotChangeBtnState:NO];
            [self.videoIntercomManager changeAVCaptureDevicePosition:NO];

        }
    }
    else{
        self.phoneShotIsOpen = YES;
        
        [self.videoView refeshPhoneShotBtnState:YES];
        
        [self.videoIntercomManager startCamera];
        [self.videoIntercomManager devControlAVTalk:DevControlAVCommandContinue retryNum:2];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:KEY_ISScreenVideoCloseCamera];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_ISScreenVideoBackGroundCamera]) {
            [self.videoView refeshPhoneShotChangeBtnState:YES];
            [self.videoIntercomManager changeAVCaptureDevicePosition:YES];
        } else {
            [self.videoView refeshPhoneShotChangeBtnState:NO];
            [self.videoIntercomManager changeAVCaptureDevicePosition:NO];

        }
    }
}

#pragma mark -
-(void)startTiming{
    if(self.timer){
        return;
    }
    self.videoView.videoTimeLab.hidden = NO;
    self.secNum = 0;
    self.videoView.videoTimeLab.text = @"00:00";
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerRecording) userInfo:nil repeats:YES];
}

//MARK: 处理视频对讲初始化结果
-(void)dealWithInitVideoIntercom:(BOOL)success error:(int)error{
    if(success){
        //开始计时
        [self startTiming];
        //按钮变成可点击
        [self.videoView videoTalkInitSuccess];
        //摄像头开始显示画面
        [self.videoIntercomManager setCameraVideoView:self.videoView.yuvView];
        //麦克风权限
        self.microphoneAuthorizationIsOpen = [self checkMicrophoneAbilityNeedTip];
        //相机权限
        self.cameraAuthorizationIsOpen = [self checkCameraAbilityNeedTip];
        if(self.cameraAuthorizationIsOpen){
            if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_ISScreenVideoCloseCamera]) {
                //停止录制视频
                [self.videoIntercomManager stopCamera];
                [self.videoView refeshPhoneShotBtnState:NO];
                self.phoneShotIsOpen = NO;
            } else {
                //开始录制视频
                [self.videoIntercomManager startCamera];
                [self.videoView refeshPhoneShotBtnState:YES];
                self.phoneShotIsOpen = YES;
            }
            if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_ISScreenVideoBackGroundCamera]) {
                [self.videoView refeshPhoneShotChangeBtnState:YES];
                [self.videoIntercomManager changeAVCaptureDevicePosition:YES];
            } else {
                [self.videoView refeshPhoneShotChangeBtnState:NO];
                [self.videoIntercomManager changeAVCaptureDevicePosition:NO];
            }
           
        }
        if(self.microphoneAuthorizationIsOpen){
            //开启手机音频采集
            [self.videoIntercomManager startRecord];
            [self.videoView refeshMicroPhoneBtnState:YES];
        }

        if (self.mediaPlayer) {
            [self.videoView refeshAudioBtnState:YES];
            [self.mediaPlayer openSound:100];
        }
    }else{
        if (error == -400012) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD showWithStatus:TS("TR_deviceIsConnected")];
                [self leftBtnClicked];
            });
        }
        [self.videoView.phoneShotBtn setImage:[UIImage imageNamed:@"ic_call_lens_close"] forState:UIControlStateNormal];
    }
}

//MARK: 开启预览回调
- (void)mediaPlayer:(MediaplayerControl*)mediaPlayer startResult:(int)result DSSResult:(int)dssResult {
    if (result < 0) {
        if (result == EE_DVR_PASSWORD_NOT_VALID || result == -11318 || result == EE_DVR_LOGIN_USER_NOEXIST) //密码错误，弹出密码修改框
        {
            [SVProgressHUD dismiss];
            ChannelObject *channel = [[DeviceControl getInstance] getSelectChannel];
            DeviceObject *device = [[DeviceControl getInstance] GetDeviceObjectBySN:channel.deviceMac];
            
            
            int tag = result;
            int errorResult = dssResult;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                int tagDeal = errorResult  == EE_DVR_PASSWORD_NOT_VALID?tag + 1000:tag;
                
                //弹出密码输入框
                [UIView showUserOrPasswordErrorTips:errorResult delegate:self presentedVC:self tag:tagDeal devID:mediaPlayer.devID changePwd:NO];
            });
            
            return;
        }
        [MessageUI ShowErrorInt:result];
    }else {
        if (dssResult == XM_NET_TYPE_DSS) { //DSS 打开视频成功
            
        }else if (dssResult == XM_NET_TYPE_RPS){//RPS打开预览成功
             
         }
        
        [self.playView playViewBufferIng];
        
        ChannelObject *channel = [[DeviceControl getInstance] getSelectChannel];
        DeviceObject *devObject = [[DeviceControl getInstance] GetDeviceObjectBySN:channel.deviceMac];
        if (devObject.nType == XM_DEV_DOORBELL || devObject.nType == XM_DEV_CAT || devObject.nType == CZ_DOORBELL || devObject.nType == XM_DEV_INTELLIGENT_LOCK || devObject.nType == XM_DEV_DOORBELL_A || devObject.nType == XM_DEV_DOORLOCK_V2) {
            // 开始开启设备信息主动上报
            [[DoorBellModel shareInstance] beginUploadData:channel.deviceMac];
            // 设备信息上报回调
            [DoorBellModel shareInstance].DevUploadDataCallBack = ^(NSDictionary *state, NSString *devMac) {
                // state 个字段表示的意思
                //                    DevStorageStatus 表示存储状态： -2：设备存储未知 -1：存储设备被拔出 0：没有存储设备 1：有存储设备 2：存储设备插入
                //                    electable 表示充电状态：0：未充电 1：正在充电 2：电充满 3：未知（表示各数据不准确）
                //                    freecapacity = 0;
                //                    percent = "-1";
                
                NSLog(@"DoorBellModel %@",state);
            };
        }
    }
    
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:KEY_ISScreenVideoEnter]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KEY_ISScreenVideoEnter];
    }
}

//MARK: 收到视频宽高比信息
-(void)mediaPlayer:(MediaplayerControl*)mediaPlayer width:(int)width htight:(int)height {
    NSLog(@"width = %d; height = %d",width, height);
    return;
}

#pragma mark - 缓冲
-(void)mediaPlayer:(MediaplayerControl*)mediaPlayer buffering:(BOOL)isBuffering ratioDetail:(double)ratioDetail{
    PlayView *pview = [self.playViewArray objectAtIndex:mediaPlayer.index];
    if (isBuffering == YES) {//开始缓冲
        [pview playViewBufferIng];
        
    }else{//缓冲完成
        // 预览开始时抓张设备缩略图 当背景
        DeviceObject *dev = [[DeviceControl getInstance] GetDeviceObjectBySN: mediaPlayer.devID];
        NSString* thumbnailPathName = [NSString devThumbnailFile:mediaPlayer.devID andChannle:0];
        FUN_MediaGetThumbnail(mediaPlayer.player, thumbnailPathName.UTF8String,1);
        [pview playViewBufferEnd];
        //判断设备长宽以及 是否是一路码流上下分屏
        if(dev.imageWidth != 0 && dev.imageHeight != 0 && dev.iSceneType == XMVR_TYPE_TWO_LENSES){
            [self mediaId: mediaPlayer.devID codecType: dev.iCodecType scene: dev.iSceneType];
        }
        
    }
}

//MARK: - 检测是否开启麦克风权限
- (bool)checkMicrophoneAbilityNeedTip{
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {
        return YES;
    }else if (videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied){
        return NO;
    }
    return YES;
}

//MARK: - 检测是否开启相机权限
- (bool)checkCameraAbilityNeedTip{
    //判断相机权限是否开启
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        return NO;
    }else if (authStatus == AVAuthorizationStatusNotDetermined){
        return YES;
    }
    return YES;
}

#pragma mark - 视频对讲计时
-(void)timerRecording
{
    self.secNum = self.secNum + 1;
    self.videoView.videoTimeLab.text = [self timeFormatted:self.secNum];
}

- (NSString *)timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    if(hours > 0){
        return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    }
    else{
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
}

#pragma mark - lazyload
-(VideoIntercomView *)videoView{
    if(!_videoView){
        _videoView = [[VideoIntercomView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
        _videoView.backgroundColor = [UIColor clearColor];
        __weak typeof(self) weakSelf = self;
        _videoView.phoneShotChangeAction = ^{
            [weakSelf phoneShotChange];
        };
        _videoView.hangUpAction = ^{
            [weakSelf hangUp];
        };
        _videoView.phoneShotAction = ^{
            [weakSelf phoneShotAction];
        };
        _videoView.audioAction = ^{
            [weakSelf audioAction];
        };
        _videoView.microphoneAction = ^{
            [weakSelf microphoneAction];
        };
    }
    
    return _videoView;
}

-(UIView *)cameraView {
    if (!_cameraView) {
        _cameraView = [[UIView alloc] init];
    }
    
    return _cameraView;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
-(MediaplayerControl *)mediaPlayer {
    if (!_mediaPlayer) {
        _mediaPlayer = [[MediaplayerControl alloc] init];
        _mediaPlayer.delegate = self;
        _mediaPlayer.isVideoIntercom = YES;
    }
    return _mediaPlayer;
}

-(NSMutableArray *)arrayDevIds{
    if(!_arrayDevIds){
        _arrayDevIds = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    return _arrayDevIds;
}

- (NSMutableArray *)playViewArray{
    if(!_playViewArray){
        _playViewArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _playViewArray;
}

- (VideoIntercomManager *)videoIntercomManager{
    if (!_videoIntercomManager) {
        _videoIntercomManager = [[VideoIntercomManager alloc] init];
        _videoIntercomManager.focusdevID = self.devID;
        _videoIntercomManager.isBackGroundCamera = self.isBackGroundCamera;
        _videoIntercomManager.isCloseCamera = self.isCloseCamera;
        
        __weak typeof(self) weakSelf = self;
        _videoIntercomManager.initVideoIntercomCallBack = ^(BOOL success, int error) {
             [weakSelf dealWithInitVideoIntercom:success error:error];
        };
        _videoIntercomManager.closeVideoIntercomCallBack = ^(BOOL success, int error) {
            
        };
    }
    
    return _videoIntercomManager;
}

- (JFHangUpPopView *)hangUpPopView {
    if (!_hangUpPopView) {
        _hangUpPopView = [[JFHangUpPopView alloc] init];
        
    }
    return _hangUpPopView;
}

- (PlayView *)playView{
    if(!_playView){
        _playView = [[PlayView alloc] initWithFrame:CGRectMake(0, NavAndStatusHight, ScreenWidth, realPlayViewHeight)];
        _playView.playViewDelegate = self;
        _playView.activityView.center = _playView.center;
    }
    return _playView;
}
@end
