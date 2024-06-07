//
//  JFScreenCameraCallVc.h
//   iCSee
//
//  Created by kevin on 2023/11/25.
//  Copyright © 2023 xiongmaitech. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JFScreenCameraCallVc : UIViewController
@property (nonatomic, copy) NSString *devID;
@property (nonatomic, copy) NSString *alarmID;
@property (nonatomic, copy) void (^clickbuttonBlock)(void);
@end

NS_ASSUME_NONNULL_END
