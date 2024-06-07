//
//  DeviceAudioPlayViewController.h
//  FunSDKDemo
//
//  Created by plf on 2024/4/26.
//  Copyright © 2024 plf. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceAudioPlayViewController : UIViewController

@property (nonatomic,copy) NSString *devID;

@property (nonatomic,assign) int channelNum;

@end

NS_ASSUME_NONNULL_END
