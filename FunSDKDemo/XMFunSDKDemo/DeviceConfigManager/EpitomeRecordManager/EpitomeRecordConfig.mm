//
//  EpitomeRecordConfig.m
//  FunSDKDemo
//
//  Created by feimy on 2024/6/14.
//  Copyright © 2024 feimy. All rights reserved.
//

#import "EpitomeRecordConfig.h"
#import <FunSDK/FunSDK.h>

@interface EpitomeRecordConfig ()

@property (nonatomic,strong) NSMutableDictionary *epitomeRecordDict;

@end

@implementation EpitomeRecordConfig

- (void)getEpitomeRecordConfig{
    //获取通道
    ChannelObject *channel = [[DeviceControl getInstance] getSelectChannel];
    FUN_DevGetConfig_Json(self.msgHandle, CSTR(channel.deviceMac), "Storage.EpitomeRecord", 1024);
}

//MARK: - 保存缩影录像配置
- (void)saveEpitomeRecordConfig{
    ChannelObject *channel = [[DeviceControl getInstance] getSelectChannel];
    NSDictionary* jsonDic1 = @{@"Name":@"Storage.EpitomeRecord",@"Storage.EpitomeRecord":self.epitomeRecordDict};
    NSError *error;
    NSData *jsonData1 = [NSJSONSerialization dataWithJSONObject:jsonDic1 options:NSJSONWritingPrettyPrinted error:&error];
    NSString *pCfgBufString1 = [[NSString alloc] initWithData:jsonData1 encoding:NSUTF8StringEncoding];
    FUN_DevSetConfig_Json(self.msgHandle, CSTR(channel.deviceMac), "Storage.EpitomeRecord", [pCfgBufString1 UTF8String], (int)(strlen([pCfgBufString1 UTF8String]) + 1));
}

//MARK: - 获取缩影录像开关
- (BOOL)getEpitomeRecordEnable{
    return [[self.epitomeRecordDict objectForKey: @"Enable"] boolValue];
}

//MARK: - 设置缩影录像开关
- (void)setEpitomeRecordEnable:(BOOL)enable{
    [self.epitomeRecordDict setObject: [NSNumber numberWithBool: enable] forKey: @"Enable"];
}


//MARK: - 获取抽帧间隔
- (int)getEpitomeRecordInterval{
    return [[self.epitomeRecordDict objectForKey: @"Interval"] intValue];
}

//MARK: - 设置抽帧间隔
- (void) setEpitomeRecordInterval:(int)interval{
    [self.epitomeRecordDict setObject: [NSNumber numberWithInt: interval] forKey: @"Interval"];
}

//MARK: - 获取开始时间
- (NSString *)getEpitomeReconrdStartTime{
    return [[self.epitomeRecordDict objectForKey: @"StartTime"] stringValue];
}

//MARK: - 设置开始时间
- (void)setEpitomeReconrdStartTime:(NSString *)startTime{
    [self.epitomeRecordDict setObject: startTime forKey: @"StartTime"];
}

//MARK: - 获取结束时间
- (NSString *)getEpitomeReconrdEndTime{
    return [[self.epitomeRecordDict objectForKey: @"EndTime"] stringValue];
}

//MARK: - 设置结束时间
- (void)setEpitomeReconrdEndTime:(NSString *)endTime{
    [self.epitomeRecordDict setObject: endTime forKey: @"EndTime"];
}

//MARK: - 设置当天录像工作时间表（与开始时间 结束时间冲突可能会冲突）
/**
 "1 00:00:00-24:00:00"，前面的1代表此工作时间段生效，0则不生效；
 最多可配置6个工作时间段；
 当时间表里的时间段和"StartTime""EndTime"有冲突时，以后者为准。
 */
- (void)setEpitomeReconrdTimeSection{
    NSMutableArray *exampleArray = @[@"1 00:00:00-23:59:59",
                                     @"0 00:00:00-00:00:00",
                                     @"0 00:00:00-00:00:00",
                                     @"0 00:00:00-00:00:00",
                                     @"0 00:00:00-00:00:00",
                                     @"0 00:00:00-00:00:00"];
    [self.epitomeRecordDict setObject: exampleArray forKey: @"TimeSection"];
}

- (void)OnFunSDKResult:(NSNumber *) pParam{
    NSInteger nAddr = [pParam integerValue];
    MsgContent *msg = (MsgContent *)nAddr;
    
    switch (msg->id) {
        case EMSG_DEV_GET_CONFIG_JSON:
        {
            if ([OCSTR(msg->szStr) isEqualToString:@"Storage.EpitomeRecord"]){
                if (msg->param1>=0) {
                    NSData *jsonData = [NSData dataWithBytes:msg->pObject length:strlen(msg->pObject)];
                    NSError *error;
                    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
                    if(error){
                        return;
                    }
                    self.epitomeRecordDict = [[jsonDic objectForKey:@"Storage.EpitomeRecord"] mutableCopy];
                }
                if (self.epConfigDelegate && [self.epConfigDelegate respondsToSelector: @selector(getEpitomeRecordConfigResult:)]) {
                    [self.epConfigDelegate getEpitomeRecordConfigResult: msg->param1];
                }
            }
            
                
        }
            break;
        case EMSG_DEV_SET_CONFIG_JSON:
        {
            if ([OCSTR(msg->szStr) isEqualToString:@"Storage.EpitomeRecord"]){
                if (self.epConfigDelegate && [self.epConfigDelegate respondsToSelector: @selector( saveEpitomeRecordConfigResult:)]) {
                    [self.epConfigDelegate saveEpitomeRecordConfigResult: msg->param1];
                }
            }
                
        }
            break;
        default:
            break;
    }
}

- (NSMutableDictionary *)epitomeRecordDict{
    if (!_epitomeRecordDict) {
        _epitomeRecordDict = [[NSMutableDictionary alloc] initWithCapacity: 0];
    }
    return _epitomeRecordDict;
}

@end
