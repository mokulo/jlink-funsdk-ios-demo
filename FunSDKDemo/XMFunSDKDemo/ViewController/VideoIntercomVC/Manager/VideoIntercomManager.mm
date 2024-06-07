//
//  VideoIntercomManager.m
//  JLink
//
//  Created by 吴江波 on 2023/11/14.
//

#import "VideoIntercomManager.h"
#import <FunSDK/FunSDK.h>
#import <FunSDK/Fun_CM.h>
#import "Recode.h"
#import "JFCaptureManager.h"
#import <FunSDK/Fun_WebRtcAudio.h>
#import <FunSDK/FunSDK.h>
#import "AudioUnitAECRecorder.h"

@interface VideoIntercomManager ()<JFVideoCaptureDelegate,AudioRecordDelegate,AECRecorderDelegate>
{
    JFCaptureManager *captureManager;
    Recode *audioRecord;
//    BOOL needChangePhoneShot; //  是否需要切换摄像头
    AVCaptureDevicePosition currentPosition;
    AudioUnitAECRecorder *aecRecorder;
    
    NSMutableData *sendData;
}
@property (nonatomic,assign) int retryNum;
@property (nonatomic,assign) int retryStartNum;//视频对讲初始化重试次数
@property (nonatomic,assign) int avTalkHandle;//
@property (nonatomic,strong) NSMutableDictionary *decoderPramDic;
@property (nonatomic,strong) UIView *videoView;
@property (nonatomic,assign) int controlRetryNum;//DevControlAVTalk重试次数
@property (nonatomic,assign) int SampleRate;// 设备支持的采样率
@property (nonatomic,assign) int videoW;// 设备支持的宽
@property (nonatomic,assign) int videoH;// 设备支持的高

@property (nonatomic,assign) BOOL webRtcAudioIsInit;//回声消除是否初始化
@property (nonatomic,assign) BOOL isStopRecord;
@end

@implementation VideoIntercomManager

- (instancetype)init{
    self = [super init];
    if (self) {
        self.msgHandle = FUN_RegWnd((__bridge void*)self);
        currentPosition = AVCaptureDevicePositionFront;
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
        self.isStopRecord = NO;
        //test
        self.webRtcAudioIsInit = NO;
        //test
        if (sendData == nil) {
            sendData = [[NSMutableData alloc] init];
        }
    }
    
    return self;
}

- (void)dealloc{
    FUN_UnRegWnd(self.msgHandle);
    self.msgHandle = -1;
}

#pragma mark - 手机前后镜头切换
-(void)changeAVCaptureDevicePosition:(BOOL)isBackgroundCamera{
    if (isBackgroundCamera) {
         
        [captureManager changeAVCaptureDevicePosition:YES];
         
        currentPosition = AVCaptureDevicePositionBack;
    } else {
         
        [captureManager changeAVCaptureDevicePosition:NO];
         
        currentPosition = AVCaptureDevicePositionFront;
    }
}

#pragma mark -  视频对讲初始化(分两步：1.获取解码能力,2.开始音视频对讲)
-(void)initVideoIntercom{
    self.retryNum = 3;
    [self getDecoderPram];
}

#pragma mark -  终止视频对讲(音频和视频)
-(void)stopVideoIntercom{
     
    if (aecRecorder) {
        [aecRecorder stopRecord];
        aecRecorder = nil;
        //test
        //WebRtcAudio_UnInit();
        //self.webRtcAudioIsInit = NO;
        //test
    }
    [self devEndAVTalk];
}

#pragma mark - 客户端主动结束解码
-(void)appEndDecoding{
    char cfg4[1024];
    snprintf(cfg4,1024, "{ \"Name\" : \"AVTalk\",\"SessionID\" : \"0x00000001\", \"AVTalk\":{\"Action\" : \"Stop\",\"Channel\" : 0}}");
    FUN_DevCmdGeneral(self.msgHandle, [self.focusdevID UTF8String], 1415, "AVTalk", 4096, 15000, (char *)cfg4, (int)strlen(cfg4) + 1, -1, 0);
}
#pragma mark - 客户端暂停视频解码 或者恢复视频解码   app关闭摄像头
-(void)appPauseVideoDecoding{
    char cfg4[1024];
    snprintf(cfg4,1024, "{ \"Name\" : \"AVTalk\",\"SessionID\" : \"0x00000001\", \"AVTalk\":{\"Action\" : \"VDPause\"}}");
    FUN_DevCmdGeneral(self.msgHandle, [self.focusdevID UTF8String], 1415, "AVTalk", 4096, 15000, (char *)cfg4, (int)strlen(cfg4) + 1, -1, 0);
}
-(void)appResumeVideoDecoding{
    char cfg4[1024];
    snprintf(cfg4,1024, "{ \"Name\" : \"AVTalk\",\"SessionID\" : \"0x00000001\", \"AVTalk\":{\"Action\" : \"VDResume\"}}");
    FUN_DevCmdGeneral(self.msgHandle, [self.focusdevID UTF8String], 1415, "AVTalk", 4096, 15000, (char *)cfg4, (int)strlen(cfg4) + 1, -1, 0);
}
#pragma mark 获取解码能力
-(void)getDecoderPram{
    NSString *logstr = [NSString stringWithFormat:@"第%d次获取DecoderPram", 4- self.retryNum];
    Fun_Log([logstr UTF8String]);
    char cfg4[1024];
    snprintf(cfg4,1024, "{ \"Name\" : \"DecoderPram\",\"SessionID\" : \"0x00000001\"}");
    FUN_DevCmdGeneral(self.msgHandle, [self.focusdevID UTF8String], 1360, "DecoderPram", 4096, 15000, (char *)cfg4, (int)strlen(cfg4) + 1, -1, 1802);
}

#pragma mark - 是否需要切换摄像头
//-(void)setIfNeedChangePhoneShot:(BOOL)need{
//    needChangePhoneShot = need;
//}

#pragma mark - 获取当前相机的方向（前(0)/后(1)）
-(int)getCurrentDevicePosition{
    return [captureManager getCurrentPosition];
}

#pragma mark - 开始录制视频
- (void)startCamera {
    if (!captureManager) {
        captureManager = [[JFCaptureManager alloc] init];
        [captureManager setDeviceFrameRate:16];
        
//        //测试
//        [captureManager setDeviceFrameWidth:640 frameHeight:480];
////        [captureManager setDeviceFrameWidth:320 frameHeight:240];
        
        captureManager.captureDelegate = (id)self;
        if (self.videoView) {
            CGRect rect = self.videoView.frame;
            captureManager.previewLayer.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
            [self.videoView.layer addSublayer:captureManager.previewLayer];
        }
    }
    
//    if(needChangePhoneShot){
//        if(currentPosition == AVCaptureDevicePositionBack){
//            [captureManager setNeedChangePhoneShot:needChangePhoneShot];
//            currentPosition = AVCaptureDevicePositionFront;
//        }else{
//            currentPosition = AVCaptureDevicePositionBack;
//        }
//        needChangePhoneShot = NO;
//    }
    
    [captureManager startCamera];
}

#pragma mark - 设置摄像头显示界面
-(void)setCameraVideoView:(UIView *)videoView
{
    self.videoView = videoView;
}

#pragma mark - 停止录制视频
- (void)stopCamera {
    [captureManager stopCamera];
}

#pragma mark - 开启手机音频采集
-(int)startRecord{
    
    if (aecRecorder) {
        [aecRecorder stopRecord];
        aecRecorder = nil;
        //test
        //WebRtcAudio_UnInit();
        //self.webRtcAudioIsInit = NO;
        //test
    }
    
    if (!aecRecorder) {
        aecRecorder = [[AudioUnitAECRecorder alloc] init];
        aecRecorder.SampleRate = self.SampleRate;
        aecRecorder.aecRecorderDelegate = self;
    }
    //test
    //WebRtcAudio_UnInit();
    //self.webRtcAudioIsInit = NO;
    //test
    self.isStopRecord = NO;
    [aecRecorder startRecord:@"" aecOn:YES];
    return 0;
}

#pragma mark - 手机停止音频采集
-(int)stopRecord{
    if (aecRecorder) {
        self.isStopRecord = YES;
        //test
        //WebRtcAudio_UnInit();
        //self.webRtcAudioIsInit = NO;
        //test
    }
    return 0;
}

#pragma mark - 发送采集到的音频数据
- (void)audioRecordData:(char*) data size:(int)size
{
    //WebRtcAudio_Process(data, size);
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
    long long curTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [dic setObject:[NSString stringWithFormat:@"%lld",curTime] forKey:@"timestamp"];//时间戳，整型字符串，精确到毫秒
    [dic setObject:[NSNumber numberWithInt:2] forKey:@"type"];//< 1:视频 2：音频
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *pCfgBufString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    Fun_DevSendAVTalkData(self.avTalkHandle, [pCfgBufString UTF8String], data, size);
}

- (void)aecAudioRecordData:(char*) datas size:(int)size{
    if (self.isStopRecord) {
        return;
    }
    if (size == 640 && sendData.length == 0) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
        long long curTime = [[NSDate date] timeIntervalSince1970] * 1000;
        [dic setObject:[NSString stringWithFormat:@"%lld",curTime] forKey:@"timestamp"];//时间戳，整型字符串，精确到毫秒
        [dic setObject:[NSNumber numberWithInt:2] forKey:@"type"];//< 1:视频 2：音频
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        NSString *pCfgBufString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        Fun_DevSendAVTalkData(self.avTalkHandle, [pCfgBufString UTF8String], datas, size);
    }else{
        [sendData appendBytes:datas length:size];
        if (sendData.length >= kFrameSize) {
            NSData *tempData = [sendData subdataWithRange:NSMakeRange(0, kFrameSize)];
            [sendData replaceBytesInRange:NSMakeRange(0, kFrameSize) withBytes:NULL length:0];
            
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
            long long curTime = [[NSDate date] timeIntervalSince1970] * 1000;
            [dic setObject:[NSString stringWithFormat:@"%lld",curTime] forKey:@"timestamp"];//时间戳，整型字符串，精确到毫秒
            [dic setObject:[NSNumber numberWithInt:2] forKey:@"type"];//< 1:视频 2：音频
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *pCfgBufString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            Fun_DevSendAVTalkData(self.avTalkHandle, [pCfgBufString UTF8String], (char*)[tempData bytes], kFrameSize);
            
        }
        
        if (sendData.length >= kFrameSize) {
            NSData *tempData = [sendData subdataWithRange:NSMakeRange(0, kFrameSize)];
            [sendData replaceBytesInRange:NSMakeRange(0, kFrameSize) withBytes:NULL length:0];
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
            long long curTime = [[NSDate date] timeIntervalSince1970] * 1000;
            [dic setObject:[NSString stringWithFormat:@"%lld",curTime] forKey:@"timestamp"];//时间戳，整型字符串，精确到毫秒
            [dic setObject:[NSNumber numberWithInt:2] forKey:@"type"];//< 1:视频 2：音频
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *pCfgBufString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            Fun_DevSendAVTalkData(self.avTalkHandle, [pCfgBufString UTF8String], (char*)[tempData bytes], kFrameSize);
        }
    }
    return;

}

//5.代理方法
#pragma mark - Delegate
#pragma mark 摄像头视频数据回调
- (void)videoCaptureCallback:(unsigned char*_Nullable)yuv width:(float)width height:(float)height {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
    long long curTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [dic setObject:[NSString stringWithFormat:@"%lld",curTime] forKey:@"timestamp"];//时间戳，整型字符串，精确到毫秒
    [dic setObject:[NSNumber numberWithInt:1] forKey:@"type"];//< 1:视频 2：音频
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *pCfgBufString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    Fun_DevSendAVTalkData(self.avTalkHandle, [pCfgBufString UTF8String], (const char*)yuv, width*height*3/2);
}

#pragma mark -  关闭音视频对讲
-(void)devEndAVTalk{
    Fun_DevStopAVTalkData(self.avTalkHandle);
}
#pragma mark - 控制音视频对讲(E_AVTALK_CONTROL_PAUSE = 0(暂停) E_AVTALK_CONTROL_CONTINUE = 1(恢复))
-(void)devControlAVTalk:(DevControlAVCommand)control retryNum:(int)num{
    if(num > 0){
        self.controlRetryNum = num;
    }
    [self devControlAVTalk:control];
}

-(void)devControlAVTalk:(DevControlAVCommand)control{
    /**
     * @brief 控制音视频对讲(Client-->Dev)
     * @details 异步回调消息：id:5559 param1: >=0 成功，否者失败  param2对应传入参数nControl
     * @param hPlayer 媒体功能控制句柄
     * @param szCtrlJson 配置信息JSON
     * @example
     * {
     *      "command":"video_pause", ///< 控制命令字段 "video_continue","switching_resolution"
     *      "info":   ///< 详细配置信息
     *   {
     *       "srcwidth":80, ///< 输入源宽度  80~【必传】
     *       "srcheight":80, ///< 输入源高度 80~【必传】
     *       "dstwidth":80, ///< 输出源宽度  80~【默认值:srcwidth】
     *       "dstheight":80, ///< 输出源高度 80~【默认值:srcheight】
     *      }
     * }
     */
    
    NSMutableDictionary *infoDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    int dstWidth = self.videoW;//输出
    int dstHeight = self.videoH;
    int srcWidth = 480;//输入
    int srcHeight = 640;
    
    [infoDic setObject:[NSNumber numberWithInt:srcWidth] forKey:@"srcwidth"];
    [infoDic setObject:[NSNumber numberWithInt:srcHeight] forKey:@"srcheight"];
    [infoDic setObject:[NSNumber numberWithInt:dstWidth] forKey:@"dstwidth"];
    [infoDic setObject:[NSNumber numberWithInt:dstHeight] forKey:@"dstheight"];
    
    NSMutableDictionary *jsonDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    if(control == DevControlAVCommandPause){
        [jsonDic setObject:[NSString stringWithFormat:@"%s",kAVTalkCtrlVideoPause] forKey:@"command"];
    }
    else if(control == DevControlAVCommandContinue){
        [jsonDic setObject:[NSString stringWithFormat:@"%s",kAVTalkCtrlVideoContinue] forKey:@"command"];
    }
    else if(control == DevControlAVCommandContinue){
        [jsonDic setObject:[NSString stringWithFormat:@"%s",kAVTalkCtrlVideoSwitchingResolution] forKey:@"command"];
    }
    [jsonDic setObject:infoDic forKey:@"info"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *pCfgBufString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    Fun_DevControlAVTalk(self.avTalkHandle,[pCfgBufString UTF8String],control);
    
    
    
    
    
    
    
//    Fun_DevControlAVTalk(self.avTalkHandle,control);
}

#pragma mark -  开启音视频对讲
-(void)devStartAVTalk{
    /**
     * @brief 开启音视频对讲(Client-->Dev)
     * @details 异步回调消息：id:5556 param1: >=0 成功，否者失败
     * @param szDevID 设备ID
     * @param szReqJson 请求信息
     * @example
     * {
     *    "protocoltype" : 0, ///< 传输数据格式协议类型枚举，暂定netip+xm私有码流格式【默认值:0】
     *    "channel" : 0, ///< 通道号 【默认值:-1】
     *    "version" : 1, ///< XM私有码流头信息格式  0:V1版本【默认值】 1:V2版本
     *    "timestamp" : "1697694748000", ///< 第一个I帧时间戳，也就是最开始时间戳
     *    "timeout" : 5000, ///< 数据发送超时时间
     *    "videoinfo"
     *    {
     *       "encodetype" : "H264", ///< 编码类型【必传】
     *       "srcwidth" : 80, ///< 输入源宽度  80~【必传】
     *       "srcheight" : 80, ///< 输入源高度 80~【必传】
     *       "dstwidth" : 80, ///< 输出源宽度  80~【默认值:srcwidth,暂时必须和srcwidth一样，不支持重采样】
     *       "dstheight" : 80, ///< 输出源高度 80~【默认值:srcheight,暂时必须和srcheight一样，不支持重采样】
     *       "fps" : 8, ///< 帧率【默认值:10】
     *       "gopsize" : 2 ///< I帧间隔 2是I帧帧率倍数不是个数【默认值:2】
     *    },
     *    "audioinfo"
     *    {
     *      "encodetype" : "g711a", ///< 编码类型【必传】
     *      "channels" : 1, ///< 通道数量【默认值:1】
     *      "bit" : 16, ///< 比特率【默认值:16】
     *      "samplerate" : 8000, ///< 采样率【默认值:8000】
     *    }
     * }
     */
    
    NSString *logstr = [NSString stringWithFormat:@"第%d次开启音视频对讲", 4 - self.retryStartNum];
    Fun_Log([logstr UTF8String]);
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
    [dic setObject:[NSNumber numberWithInt:0] forKey:@"protocoltype"];
    [dic setObject:[NSNumber numberWithInt:0] forKey:@"channel"];
    [dic setObject:[NSNumber numberWithInt:0] forKey:@"version"];
    //[dic setObject:[NSNumber numberWithInt:0] forKey:@"timestamp"];
    [dic setObject:[NSNumber numberWithInt:5000] forKey:@"timeout"];
    if (self.isCloseCamera) {
        [dic setObject:[NSNumber numberWithInt:E_AVTALK_SEND_MEDIA_TYPE_AUDIO] forKey:@"mediatype"];
    } else {
        [dic setObject:[NSNumber numberWithInt:E_AVTALK_SEND_MEDIA_TYPE_ALL] forKey:@"mediatype"];
    }
    
    NSMutableDictionary *audioInfoDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    [audioInfoDic setObject:@"g711a" forKey:@"encodetype"];
    [audioInfoDic setObject:[NSNumber numberWithInt:1] forKey:@"channels"];
    [audioInfoDic setObject:[NSNumber numberWithInt:[self getDeviceSampleBits]] forKey:@"bit"];
    [audioInfoDic setObject:[NSNumber numberWithInt:[self getDeviceSampleRate]] forKey:@"sampleRate"];
    [dic setObject:audioInfoDic forKey:@"audioinfo"];
    
    int dstWidth = self.videoW;//输出
    int dstHeight = self.videoH;
    int srcWidth = 480;//输入
    int srcHeight = 640;
    
    int fps = [self getDeviceFps];
    [captureManager setDeviceFrameRate:fps];
//    [captureManager setDeviceFrameWidth:srcHeight frameHeight:srcWidth];
    NSString *enc = [self getDeviceEnc];
    NSMutableDictionary *videoInfoDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    [videoInfoDic setObject:enc forKey:@"encodetype"];
    
    [videoInfoDic setObject:[NSNumber numberWithInt:srcWidth] forKey:@"srcwidth"];
    [videoInfoDic setObject:[NSNumber numberWithInt:srcHeight] forKey:@"srcheight"];
    [videoInfoDic setObject:[NSNumber numberWithInt:dstWidth] forKey:@"dstwidth"];
    [videoInfoDic setObject:[NSNumber numberWithInt:dstHeight] forKey:@"dstheight"];
    [videoInfoDic setObject:[NSNumber numberWithInt:fps] forKey:@"fps"];
    [videoInfoDic setObject:[NSNumber numberWithInt:2] forKey:@"gopsize"];
    if ([enc isEqualToString:@"H265"]) {
        [videoInfoDic setObject:[NSNumber numberWithInt:E_ENCODER_PRESET_ULTRAFAST] forKey:@"preset"];
    }
    [dic setObject:videoInfoDic forKey:@"videoinfo"];

    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *pCfgBufString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    self.avTalkHandle = Fun_DevStartAVTalk(self.msgHandle, [self.focusdevID UTF8String], [pCfgBufString UTF8String], 5000);
    
    //test
    FUN_SetIntAttr(self.playHandle, EOA_SET_DEV_TALK_DATA_USER, self.msgHandle);
    //test
}

-(int)getDeviceFps{
    int fps = 10;
    if(self.decoderPramDic){
        if([self.decoderPramDic.allKeys containsObject:@"Video"]){
            NSArray *array = [self.decoderPramDic objectForKey:@"Video"];
            if(array && array.count > 0){
                NSDictionary *videoDic = [array objectAtIndex:0];
                if(videoDic && [videoDic.allKeys containsObject:@"Res"]){
                    NSArray *resArray = [videoDic objectForKey:@"Res"];
                    if(resArray && resArray.count > 0){
                        NSDictionary *resDic = [resArray objectAtIndex:0];
                        if(resDic && [resDic.allKeys containsObject:@"FPS"]){
                            fps = [[resDic objectForKey:@"FPS"] intValue];
                        }
                    }
                }
            }
        }
    }
    
    return fps;
}
-(NSString *)getDeviceEnc{
    NSString  *Enc = @"H265";
    if(self.decoderPramDic){
        if([self.decoderPramDic.allKeys containsObject:@"Video"]){
            NSArray *array = [self.decoderPramDic objectForKey:@"Video"];
            if(array && array.count > 0){
                NSDictionary *videoDic = [array objectAtIndex:0];
                NSString *videoEnc = [videoDic objectForKey:@"Enc"];
                
                if(videoEnc.length > 0){
                    Enc = videoEnc;
                }
            }
        }
    }
    
    return Enc;
}
-(int)getDeviceSampleRate{
    int SampleRate = 8000;
    if(self.decoderPramDic){
        if([self.decoderPramDic.allKeys containsObject:@"Audio"]){
            NSArray *array = [self.decoderPramDic objectForKey:@"Audio"];
            if(array && array.count > 0){
                NSDictionary *AudioDic = [array objectAtIndex:0];
                NSArray *SR = [AudioDic objectForKey:@"SR"];
                if(SR && SR.count > 0){
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO];
                    NSArray *sortedArray = [SR sortedArrayUsingDescriptors:@[sortDescriptor]];
                    SampleRate = [[sortedArray objectAtIndex:0] intValue];
                }
            }
        }
    }
    self.SampleRate = SampleRate;
    return SampleRate;
}
-(int)getDeviceSampleBits{
    int SampleBits = 16;
    if(self.decoderPramDic){
        if([self.decoderPramDic.allKeys containsObject:@"Audio"]){
            NSArray *array = [self.decoderPramDic objectForKey:@"Audio"];
            if(array && array.count > 0){
                NSDictionary *AudioDic = [array objectAtIndex:0];
                NSArray *SB = [AudioDic objectForKey:@"SB"];
                if(SB && SB.count > 0){
                     
                    SampleBits = [[SB objectAtIndex:0] intValue];
                }
            }
        }
    }
    return SampleBits;
}


-(void)getDeviceSize{
    self.videoW = 240;
    self.videoH = 320;
    if(self.decoderPramDic){
        if([self.decoderPramDic.allKeys containsObject:@"Video"]){
            NSArray *array = [self.decoderPramDic objectForKey:@"Video"];
            if(array && array.count > 0){
                NSDictionary *videoDic = [array objectAtIndex:0];
                if(videoDic && [videoDic.allKeys containsObject:@"Res"]){
                    NSArray *resArray = [videoDic objectForKey:@"Res"];
                    if(resArray && resArray.count > 0){
                        NSDictionary *resDic = [resArray objectAtIndex:0];
                        if(resDic && [resDic.allKeys containsObject:@"H"]){
                            self.videoH = [[resDic objectForKey:@"H"] intValue];
                        }
                        if(resDic && [resDic.allKeys containsObject:@"W"]){
                            self.videoW = [[resDic objectForKey:@"W"] intValue];
                        }
                    }
                }
            }
        }
    }
}
#pragma mark - 清空视频画面
-(void)clearVideoImage{
    [captureManager.previewLayer removeFromSuperlayer];
    captureManager = nil;
}

#pragma mark FunSDK 结果
- (void)baseOnFunSDKResult:(MsgContent *)msg{
    switch ( msg->id ) {
        case EMSG_ON_TALK_PCM_DATA: {
            NSData *data = [NSData dataWithBytes:msg->pObject length:msg->param1];
            //test
            if (data && data.length > 0) {
                [aecRecorder appendPCMData:data];
            } else {

            }
            //test
            
        }
            break;
        case EMSG_DEV_CMD_EN:
        {
            if ([OCSTR(msg->szStr) isEqualToString:@"DecoderPram"]) {
                if (msg->pObject == NULL|| msg ->param1 < 0) {
                    self.retryNum = self.retryNum - 1;
                    if(self.retryNum > 0){
                        [self getDecoderPram];
                    }else{
                        [SVProgressHUD dismiss];
                        Fun_Log("获取DecoderPram失败");
                        self.retryStartNum = 3;
                        [self devStartAVTalk];
                    }
                    
                    return;
                }
                NSData *retJsonData = [NSData dataWithBytes:msg->pObject length:strlen(msg->pObject)];
                
                NSError *error;
                NSDictionary *retDic = [NSJSONSerialization JSONObjectWithData:retJsonData options:NSJSONReadingMutableLeaves error:&error];
                if (!retDic) {
                    if(self.retryNum > 0){
                        [self getDecoderPram];
                    }else{
                        Fun_Log("获取DecoderPram失败");
                        self.retryStartNum = 3;
                        [self devStartAVTalk];
                    }
                    return;
                }
                Fun_Log("获取DecoderPram成功");
                self.decoderPramDic = [[retDic objectForKey:@"DecoderPram"] mutableCopy];
                [self getDeviceSize];
                self.retryStartNum = 3;
                [self devStartAVTalk];
            }
            else  if ([OCSTR(msg->szStr) isEqualToString:@"AVTalk"]) {
                if (msg ->param1 >= 0) {
                    Fun_Log("客户端主动结束解码成功");
                    if(self.appEndDecodingCallBack){
                        self.appEndDecodingCallBack(YES, 0);
                    }
                }else{
                    Fun_Log("客户端主动结束解码失败");
                    if(self.appEndDecodingCallBack){
                        self.appEndDecodingCallBack(NO, msg ->param1);
                    }
                }
                
            }
        }
            break;
        case EMSG_DEV_START_AV_TALK://开始音视频对讲
        {
            if (msg->param1 >= 0) {
                Fun_Log("开始音视频对讲成功");
                if(self.initVideoIntercomCallBack){
                    self.initVideoIntercomCallBack(YES, 0);
                }
            }else{
                self.retryStartNum = self.retryStartNum - 1;
                if(self.retryStartNum > 0){
                    [self devStartAVTalk];
                }else{
                    if(self.initVideoIntercomCallBack){
                        self.initVideoIntercomCallBack(NO, msg->param1);
                    }
                }
            }
        }
            break;
        case EMSG_DEV_AV_TALK_SEND_DATA://发送音视频对讲数据
        {
            if (msg->param1 >= 0) {
                Fun_Log("发送音视频对讲成功");
            }else{
                Fun_Log("发送音视频对讲失败");
            }
        }
            break;
        case EMSG_DEV_STOP_AV_TALK://关闭音视频对讲
        {
            if (msg->param1 >= 0) {
                Fun_Log("关闭音视频对讲成功");
                if(self.closeVideoIntercomCallBack){
                    self.closeVideoIntercomCallBack(YES, 0);
                }
            }else{
                Fun_Log("关闭音视频对讲失败");
                if(self.closeVideoIntercomCallBack){
                    self.closeVideoIntercomCallBack(NO,msg->param1);
                }
            }
            
        }
            break;
        case EMSG_DEV_CONTROL_AV_TALK://控制音视频对讲
        {
            int control = msg->param2;
            NSString *logStr;
            if (msg->param1 >= 0) {
                logStr = [NSString stringWithFormat:@"控制音视频对讲%d成功",control];
            }else{
                logStr = [NSString stringWithFormat:@"控制音视频对讲%d失败",control];
                if(self.controlRetryNum > 0){
                    self.controlRetryNum = self.controlRetryNum - 1;
                    [self devControlAVTalk:(DevControlAVCommand)control];
                }
            }
            Fun_Log([logStr UTF8String]);
        }
            break;
        default:
            break;
    }
}
@end
