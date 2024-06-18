//
//  EpitomeRecordConfig.h
//  FunSDKDemo
//
//  Created by feimy on 2024/6/14.
//  Copyright © 2024 feimy. All rights reserved.
//

#import "FunSDKBaseObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EpitomeRecordConfigDelegate <NSObject>

- (void)getEpitomeRecordConfigResult: (NSInteger) result;
- (void)saveEpitomeRecordConfigResult: (NSInteger) result;

@end


@interface EpitomeRecordConfig : FunSDKBaseObject

@property (nonatomic, assign) id<EpitomeRecordConfigDelegate> epConfigDelegate;

/**
 获取缩影编码配置
 */
- (void)getEpitomeRecordConfig;
/**
 获取结束时间
 */
- (NSString *)getEpitomeReconrdEndTime;
/**
 获取开始时间
 */
- (NSString *)getEpitomeReconrdStartTime;
/**
 获取抽帧间隔
 */
- (int)getEpitomeRecordInterval;
/**
 获取缩影录像开关
 */
- (BOOL)getEpitomeRecordEnable;
/**
 设置结束时间
 */
- (NSString *)setEpitomeReconrdEndTime:(NSString *)endTime;
/**
 设置开始时间
 */
- (NSString *)setEpitomeReconrdStartTime:(NSString *)startTime;
/**
 设置抽帧间隔
 */
- (int)setEpitomeRecordInterval:(int)interval;
/**
 设置缩影录像开关
 */
- (BOOL)setEpitomeRecordEnable:(BOOL)enable;
/**
 保存缩影录像配置
 */
- (void)saveEpitomeRecordConfig;
/**
 设置自定义时间段
 */
- (void)setEpitomeReconrdTimeSection;

@end

NS_ASSUME_NONNULL_END
