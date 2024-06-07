//
//  VideoIntercomView.h
//  JLink
//
//  Created by 吴江波 on 2023/11/7.
//

#import <UIKit/UIKit.h>
#import "YUVPlayer.h" //YUV直接显示

NS_ASSUME_NONNULL_BEGIN

@interface VideoIntercomView : UIView
@property(nonatomic, copy) void(^phoneShotAction)(void);
@property(nonatomic, copy) void(^hangUpAction)(void);
@property (nonatomic,copy) void(^phoneShotChangeAction)(void);
@property(nonatomic, copy) void(^audioAction)(void);
@property (nonatomic,copy) void(^microphoneAction)(void);
@property (nonatomic,copy) void (^doubleTapGestureCallBack)(UITapGestureRecognizer *sender,CGPoint point);
@property (nonatomic,strong) UILabel *deviceNameLab;//设备名称
@property (nonatomic,strong) UILabel *videoTimeLab;//视频时间

@property (nonatomic,strong) UIButton *phoneShotBtn;//手机摄像头开关

@property (nonatomic,strong) UIButton *hangUpBtn;//挂断按钮

@property (nonatomic,strong) UIButton *microphoneBtn;//麦克风按钮

@property (nonatomic,strong) UIButton *audioBtn;//扬声器按钮

@property (nonatomic,strong) UIButton *phoneShotChangeBtn;//手机摄像头切换开关
@property(nonatomic,strong) YUVPlayer *yuvView;

-(void)refeshMicroPhoneBtnState:(BOOL)select;
-(void)refeshAudioBtnState:(BOOL)select;
-(void)refeshPhoneShotBtnState:(BOOL)select;
#pragma mark - 刷新手机前后镜头开关状态
-(void)refeshPhoneShotChangeBtnState:(BOOL)isBackgroundCamera;
#pragma mark - 对讲初始化完成。按钮变成可点击
-(void)videoTalkInitSuccess;
#pragma mark - 刷新头像
-(void)refreshHeadImageWithUrl:(NSString *)imageUrl;
-(void)refreshHeadImageV:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
