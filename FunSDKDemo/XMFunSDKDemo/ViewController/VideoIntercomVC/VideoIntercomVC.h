//
//  VideoIntercomVC.h
//  JLink
//
//  Created by 吴江波 on 2023/11/7.
//

#import <UIKit/UIKit.h>
#import "FunSDKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
@protocol vcDismissDelegate <NSObject>
- (void)vcDidDismiss;
@end

@class MediaplayerControl;
@interface VideoIntercomVC : FunSDKBaseViewController
@property (nonatomic,strong) NSString *focusdevID;   // 焦点设备Id
@property (nonatomic,strong) MediaplayerControl *playModel;
@property (nonatomic) NSMutableArray *arrayDevIds;              // 设备Id
-(void)refreshImageWithUrl:(NSString *)imageUrl;
@property (nonatomic,assign) BOOL isCloseCamera;
@property (nonatomic,assign) BOOL isBackGroundCamera;
@property (nonatomic,assign) BOOL isFromWaitForAnswer;//从待接听页面进来
@property (nonatomic, weak) id<vcDismissDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
