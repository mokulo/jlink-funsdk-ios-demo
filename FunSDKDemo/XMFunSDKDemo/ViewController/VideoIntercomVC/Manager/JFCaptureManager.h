//
//  CaptureManager.h
//  VideoTest
//
//  Created by zhang on 2023/3/11.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol JFVideoCaptureDelegate <NSObject>
- (void)videoCaptureCallback:(unsigned char*_Nullable)yuv width:(float)width height:(float)height;
 
@end

NS_ASSUME_NONNULL_BEGIN

@interface JFCaptureManager : NSObject

@property (nonatomic,weak) id<JFVideoCaptureDelegate> captureDelegate;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


#pragma mark 初始视频相机控制器，这里初始化了手机默认相机（背部相机）
- (void) initCamera;
#pragma mark 开始摄像
- (void)startCamera;
#pragma mark 停止摄像
- (void) stopCamera;
#pragma mark 修改前后摄像头
-(void)changeAVCaptureDevicePosition:(BOOL)isBackGroundCamera;

#pragma mark 设置设备支持的帧率
- (void)setDeviceFrameRate:(int)rate;
#pragma mark 设置设备支持的视频数据宽和高
- (void)setDeviceFrameWidth:(float)width frameHeight:(float)height;
#pragma mark 设置是否需要切换摄像头
//- (void)setNeedChangePhoneShot:(BOOL)need;
#pragma mark - 获取当前相机的方向（前(0)/后(1)）
-(int)getCurrentPosition;
@end

NS_ASSUME_NONNULL_END
