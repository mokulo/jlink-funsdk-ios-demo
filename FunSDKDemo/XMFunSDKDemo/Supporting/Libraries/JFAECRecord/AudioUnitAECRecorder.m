//
//  AudioUnitAECRecorder.m
//  AudioUnitDemo
//
//  Created by devnn on 2023/3/26.
//

#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIApplication.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioUnitAECRecorder.h"
#import "RecorderDelegate.h"
#import "CommonDefine.h"
#import "Recode.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define kNumberBuffers 3
#define t_sample     SInt16
#define kSamplingRate   8000
#define kNumberChannels  1
#define kBitesPerChannels  (sizeof(t_sample) * 8)
#define kBytesPerFrame   (kNumberChannels * sizeof(t_sample))
#define kFrameSize      640
#define PacketLossLine      15 //低音量数据主动丢包 范围: 0-100，数字越小，主动丢包越少
#define MAX_LENGTH 639
@interface AudioUnitAECRecorder(){
    AUNode remoteIONode;
    AudioUnit remoteIOUnit;
    AudioStreamBasicDescription mAudioFormat;
    
    NSMutableData *bufferedData;
    NSLock *dataLock;
}
@property(nonatomic,assign) RecordState state;
@property(nonatomic,copy) NSString *originAudioSessionCategory;
@property(nonatomic,copy) NSString *filePath;
@property(nonatomic,assign) FILE *file;
@property(nonatomic,assign) BOOL isAecOn;//是否开启AEC
@property(nonatomic)NSTimer *levelTimer;
@end

@implementation AudioUnitAECRecorder

-(id)init{
    self = [super init];
    if(self){
        self.file = NULL;
        dataLock = [[NSLock alloc] init];
        bufferedData = [NSMutableData data];
        
    }
    return self;
}

//播放回调
static OSStatus PlaybackCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                                 UInt32 inNumberFrames, AudioBufferList *ioData) {
    
    AudioUnitAECRecorder *player = (__bridge AudioUnitAECRecorder *)inRefCon;
    
    // Fill the audio buffer with PCM data
    [player fillBuffer:ioData];
    
    return noErr;
}

/**
 录制回调
 */
OSStatus AECAudioInputCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *__nullable ioData) {
    NSLog(@"AECAudioInputCallback");
    AudioUnitAECRecorder *recorder = (__bridge AudioUnitAECRecorder *)inRefCon;
    
    AudioBuffer buffer;
    
    UInt32 size = inNumberFrames * recorder->mAudioFormat.mBytesPerFrame;
    buffer.mDataByteSize = size; // sample size
    buffer.mNumberChannels = 1; // one channel
    buffer.mData = malloc(size); // buffer size
    
    // we put our buffer into a bufferlist array for rendering
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status = noErr;
    
    status = AudioUnitRender(recorder->remoteIOUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList);
    
    if (status != noErr) {
        printf("AudioUnitRender %d \n", (int)status);
        return status;
    }
    
    [recorder writePCMData:buffer.mData size:buffer.mDataByteSize];
    free(buffer.mData);
    return status;
}


-(void)startRecord:(NSString *)filePath aecOn:(BOOL)aecOn{
    self.filePath = filePath;
    self.isAecOn = aecOn;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL allow){
            if(allow){
                NSLog(@"已经拥有麦克风权限");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self realStart];
                });
            }else{
                // no permission
                NSLog(@"没有麦克风权限");
            }
        }];
    }
    
}

-(void)realStart{
    [self initAudioSession];
    [self initAudioUnit];
    [self initFormat];
    [self initInputCallBack];
    [self initoutputCallback];
    [self startRecord];
}

- (void)writePCMData:(char *)buffer size:(int)size {
//    if (!self.file) {
//        self.file = fopen(self.filePath.UTF8String, "w");
//    }
//    fwrite(buffer, size, 1, self.file);
//    NSLog(@"aec pcm size: %i",size);
//
//    static char accumulatedData[MAX_LENGTH + 1] = "";  // 用于累加数据的变量
//    static int accumulatedLength = 0;  // 累加的长度
//
//    int dataLength = strlen(buffer);
//    if (dataLength + accumulatedLength < MAX_LENGTH) {
//        // 将数据追加到累加变量中
//        strcat(accumulatedData, buffer);
//        accumulatedLength += dataLength;
//    } else {
//        // 数据已满足输出长度要求，输出前640个字符
//        strncat(accumulatedData, buffer, MAX_LENGTH - accumulatedLength);
//        accumulatedData[MAX_LENGTH] = '\0';  // 确保以空字符结尾
//        printf("Output: %s\n", accumulatedData);
//        if (self.aecRecorderDelegate && [self.aecRecorderDelegate respondsToSelector:@selector(aecAudioRecordData:size:)]) {
//            [self.aecRecorderDelegate aecAudioRecordData:accumulatedData size:640];
//        }
//        // 清空累加变量，以便处理下一组数据
//        accumulatedData[0] = '\0';
//        accumulatedLength = 0;
//    }
//
    
        if (self.aecRecorderDelegate && [self.aecRecorderDelegate respondsToSelector:@selector(aecAudioRecordData:size:)]) {
            [self.aecRecorderDelegate aecAudioRecordData:buffer size:size];
        }
}


-(void)initAudioSession{
        
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    self.originAudioSessionCategory = audioSession.category;
    //[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth error:nil];
    
    [Recode setSpeakMode];
    [audioSession setPreferredIOBufferDuration:0.02 error:nil];
    
    [audioSession setActive:YES error:nil];
}

#pragma mark - 调用方法获取音量
-(BOOL)isQuite:(char *)buffer size:(int)size
{
    NSData *pcmData = [NSData dataWithBytes:buffer length:strlen(buffer)];
    if(pcmData == nil){
        return NO;
    }
    long long pcmAllLenght =0;
    short butterByte[pcmData.length/2];
    memcpy(butterByte, pcmData.bytes, pcmData.length);//frame_size * sizeof(short)
    // 将 buffer 内容取出，进行平方和运算
    for(int i =0; i < pcmData.length/2; i++)
    {
        pcmAllLenght += butterByte[i] * butterByte[i];
    }
    // 平方和除以数据总长度，得到音量大小。
    double mean = pcmAllLenght / (double)pcmData.length;
    double volume =10*log10(mean);//volume为分贝数大小
   
    if(volume > 0){
        float num = volume - 36;
//        if(num > 45){
//            NSLog(@"high volume = %f",num);
//        }else if (num <= 45 && num > 30){
//            NSLog(@"middle volume = %f",num);
//        }
//        else if (num <= 30 && num > 10){
//            NSLog(@"low volume = %f",num);
//        }
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (self.aecRecorderDelegate && [self.aecRecorderDelegate respondsToSelector:@selector(getCurrentSoundLevel:)]) {
//                [self.aecRecorderDelegate getCurrentSoundLevel:num];
//            }
//        });
    }
    return YES;
}

/**
 初始化AudioUnit
 */
-(void)initAudioUnit{
    AudioComponentDescription componentDesc;
    componentDesc.componentType = kAudioUnitType_Output;
    componentDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0;
    
    AudioComponent audioCompnent = AudioComponentFindNext(NULL, &componentDesc);
    OSStatus status = AudioComponentInstanceNew(audioCompnent, &remoteIOUnit);
    CheckError(status, "创建unit失败");
}

/**
 音频参数
 */
-(void)initFormat{
    
    mAudioFormat.mSampleRate = self.SampleRate;
    mAudioFormat.mFormatID = kAudioFormatLinearPCM;
    mAudioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mReserved = 0;
    mAudioFormat.mChannelsPerFrame = kNumberChannels;
    mAudioFormat.mBitsPerChannel = kBitesPerChannels;
    mAudioFormat.mFramesPerPacket = 1;
//    mAudioFormat.mBytesPerFrame = kBytesPerFrame;
//    mAudioFormat.mBytesPerPacket =  kBytesPerFrame;
    mAudioFormat.mBytesPerFrame = (mAudioFormat.mBitsPerChannel / 8) * mAudioFormat.mChannelsPerFrame; // 每帧的bytes数2
    mAudioFormat.mBytesPerPacket =  mAudioFormat.mFramesPerPacket*mAudioFormat.mBytesPerFrame;//每个包的字节数2
    
    UInt32 size = sizeof(mAudioFormat);
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &mAudioFormat,
                                    size),
               "kAudioUnitProperty_StreamFormat of bus 0 failed");
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    1,
                                    &mAudioFormat,
                                    size),
               "kAudioUnitProperty_StreamFormat of bus 1 failed");
    
    
    UInt32 enableFlag = 1;
    //test 开启音频输出
        CheckError(AudioUnitSetProperty(remoteIOUnit,
                                            kAudioOutputUnitProperty_EnableIO,
                                            kAudioUnitScope_Output,
                                            0,
                                            &enableFlag,
                                            sizeof(enableFlag)),
                       "Open output of bus 0 failed");
    //
    //开启麦克风
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    1,
                                    &enableFlag,
                                    sizeof(enableFlag)),
               "Open input of bus 1 failed");
}


/**
 音频输入回调:录音
 */
- (void)initInputCallBack {
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = AECAudioInputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    OSStatus status = AudioUnitSetProperty(remoteIOUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Output, 0, &callbackStruct, sizeof(callbackStruct));
    CheckError(status, "设置采集回调失败");
}

- (void)initoutputCallback {
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = PlaybackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct));
}

-(void)startRecord{
    CheckError(AudioUnitInitialize(remoteIOUnit),"AudioUnitInitialize error");
    OSStatus status = AudioOutputUnitStart(remoteIOUnit);
    CheckError(status,"AudioOutputUnitStart error");
    if(status==0){
        self.state=STATE_START;
        if (self.aecRecorderDelegate && [self.aecRecorderDelegate respondsToSelector:@selector(aecRecorderDidStart)]) {
            [self.aecRecorderDelegate aecRecorderDidStart];
        }
        [self setAecOn:YES];
    }
}

- (void)stopRecord{
    NSLog(@"audio,record stop");
    if(self.state == STATE_STOP){
        NSLog(@"audio,in recorder stop, state has stopped!");
        return;
    }
    
    AudioOutputUnitStop(remoteIOUnit);
    
    //    AudioUnitUninitialize(remoteIOUnit);
    
    AudioComponentInstanceDispose(remoteIOUnit);
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.state = STATE_STOP;
    
    self.file=NULL;
    if (self.aecRecorderDelegate && [self.aecRecorderDelegate respondsToSelector:@selector(aecRecorderDidStop)]) {
        [self.aecRecorderDelegate aecRecorderDidStop];
    }
    if(self.levelTimer){
        [self.levelTimer invalidate];
        self.levelTimer = nil;
    }
//    [self.audioRecorder stop];
//    self.audioRecorder = nil;
    //    [self audioUnitStopPlay];
}


- (void)appendPCMData:(NSData *)pcmData {
    
    [dataLock lock];
    [bufferedData appendData:pcmData];
    if (bufferedData.length > 5000) {
        NSLog(@"缓存了很多数据，没播完 bufferedData.length = %d",bufferedData.length);
    }
    [dataLock unlock];
}

/**
 运行时设置AEC开启和关闭
 */
- (void)setAecOn:(BOOL)aecOn{
    NSLog(@"setAecOn:%d",aecOn);
    self.isAecOn = aecOn;

    UInt32 EnableAGC = 1; // 1 表示启用自动增益
    AudioUnitSetProperty(remoteIOUnit,
                         kAUVoiceIOProperty_VoiceProcessingEnableAGC,
                         kAudioUnitScope_Global,
                         0,
                         &EnableAGC,
                         sizeof(EnableAGC));
    
    UInt32 echoCancellationEnabled = 0; // 0 表示启用回声消除（禁用饶过语音处理）
    AudioUnitSetProperty(remoteIOUnit,
                         kAUVoiceIOProperty_BypassVoiceProcessing,
                         kAudioUnitScope_Global,
                         0,
                         &echoCancellationEnabled,
                         sizeof(echoCancellationEnabled));
}

-(void)dealloc{
    [self stopRecord];
}

- (NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

-(BOOL)isStated{
    return self.state==STATE_START;
}

- (void)fillBuffer:(AudioBufferList *)ioData {
    [dataLock lock];
    
    if (bufferedData.length >= ioData->mBuffers[0].mDataByteSize) {
        // Copy PCM data to the audio buffer
        [bufferedData getBytes:ioData->mBuffers[0].mData length:ioData->mBuffers[0].mDataByteSize];
        
        // Remove the copied data from the buffer
        [bufferedData replaceBytesInRange:NSMakeRange(0, ioData->mBuffers[0].mDataByteSize) withBytes:NULL length:0];
    } else {
        // If there's not enough data, fill the buffer with silence
        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
    }
    
    [dataLock unlock];
}

@end
