//
//  JFHangUpPopView.h
//   iCSee
//
//  Created by kevin on 2023/12/9.
//  Copyright © 2023 xiongmaitech. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JFHangUpPopView : UIView
@property (nonatomic ,strong) UILabel *lblTitle;
@property (nonatomic ,strong) UILabel *lblSubTitle;
- (void)showWithTime:(NSString *)timeStr;
@end

NS_ASSUME_NONNULL_END
