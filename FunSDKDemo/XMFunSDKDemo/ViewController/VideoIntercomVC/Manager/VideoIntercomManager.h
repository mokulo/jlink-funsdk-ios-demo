//
//  VideoIntercomManager.h
//  JLink
//  视频对讲管理类
//  Created by 吴江波 on 2023/11/14.
//

#import <Foundation/Foundation.h>
#import "FunSDKBaseObject.h"

typedef NS_ENUM(int,DevControlAVCommand) {
    DevControlAVCommandPause,//暂停
    DevControlAVCommandContinue,//恢复
    DevControlAVCommandSwitchingResolution//修改分辨率
};
NS_ASSUME_NONNULL_BEGIN

typedef void(^InitVideoIntercomCallBack)(BOOL success,int error);
typedef void(^CloseVideoIntercomCallBack)(BOOL success,int error);
typedef void(^AppEndDecodingCallBack)(BOOL success,int error);

@interface VideoIntercomManager : FunSDKBaseObject
@property (nonatomic,strong) NSString *focusdevID;   // 焦点设备Id
@property (nonatomic,copy) InitVideoIntercomCallBack initVideoIntercomCallBack;
@property (nonatomic,copy) CloseVideoIntercomCallBack closeVideoIntercomCallBack;//关闭视频
@property (nonatomic,copy) AppEndDecodingCallBack appEndDecodingCallBack;//客户端主动结束解码
@property (nonatomic,assign) BOOL isCloseCamera;
@property (nonatomic,assign) BOOL isBackGroundCamera;

@property (nonatomic, assign) int playHandle;                    //视频播放器句柄
#pragma mark -  视频对讲初始化(1.获取解码能力,2.开始音视频对讲)
-(void)initVideoIntercom;
#pragma mark - 设置摄像头显示界面
-(void)setCameraVideoView:(UIView *)videoView;
#pragma mark -  终止视频对讲
-(void)stopVideoIntercom;
#pragma mark - 客户端主动结束解码
-(void)appEndDecoding;
#pragma mark - 客户端暂停视频解码 或者恢复视频解码   app关闭摄像头
-(void)appPauseVideoDecoding;
-(void)appResumeVideoDecoding;
#pragma mark - 开启手机音频采集
-(int)startRecord;
#pragma mark - 手机停止音频采集
-(int)stopRecord;
#pragma mark - 停止录制视频
- (void)stopCamera;
#pragma mark - 开始录制视频
- (void)startCamera;
#pragma mark - 开启音视频对讲
-(void)devStartAVTalk;
#pragma mark - 结束音视频对讲
-(void)devEndAVTalk;
#pragma mark - 控制音视频对讲(E_AVTALK_CONTROL_PAUSE = 0(暂停) E_AVTALK_CONTROL_CONTINUE = 1(恢复))
-(void)devControlAVTalk:(DevControlAVCommand)control retryNum:(int)num;
#pragma mark - 客户端主动结束解码
-(void)appStopAVTalk;
#pragma mark - 手机前后镜头切换
-(void)changeAVCaptureDevicePosition:(BOOL)isBackgroundCamera;
#pragma mark - 清空视频画面
-(void)clearVideoImage;
#pragma mark - 是否需要切换摄像头
//-(void)setIfNeedChangePhoneShot:(BOOL)need;

-(int)getCurrentDevicePosition;
@end

NS_ASSUME_NONNULL_END
