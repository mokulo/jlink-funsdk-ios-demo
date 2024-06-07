//
//  DeviceAudioPlayManager.h
//  XWorld_General
//
//  Created by Tony Stark on 20/09/2019.
//  Copyright © 2019 xiongmaitech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FunSDKBaseObject.h"

typedef void(^DeviceAudioPlayResult)(int result);
typedef void(^DeviceAudioGetAudioListResult)(int result,NSArray *list);


@interface DeviceAudioPlayManager : FunSDKBaseObject

@property (nonatomic,copy) DeviceAudioPlayResult deviceAudioPlayResult;

@property (nonatomic,copy) DeviceAudioGetAudioListResult deviceAudioGetAudioListResult;

//MARK: - 播放对应标记的音频
- (void)playAudioSign:(int)sign device:(NSString *)devID completion:(DeviceAudioPlayResult)completion;
//MARK: - 获取自定义列表
- (void)requestAudioList:(NSString *)devID completion:(DeviceAudioGetAudioListResult)completion;

@end
