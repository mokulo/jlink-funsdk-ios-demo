//
//  UIView+Layout.m
//
//  Created by XM on 18/2/24.
//  Copyright © 2018年 XM. All rights reserved.
//

#import "UIView+Layout.h"
//#import "LangTranslator.h"

@implementation UIView (Layout)

- (CGFloat)tz_left {
    return self.frame.origin.x;
}

- (void)setTz_left:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)tz_top {
    return self.frame.origin.y;
}

- (void)setTz_top:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)tz_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setTz_right:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)tz_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setTz_bottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)tz_width {
    return self.frame.size.width;
}

- (void)setTz_width:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)tz_height {
    return self.frame.size.height;
}

- (void)setTz_height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)tz_centerX {
    return self.center.x;
}

- (void)setTz_centerX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)tz_centerY {
    return self.center.y;
}

- (void)setTz_centerY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGPoint)tz_origin {
    return self.frame.origin;
}

- (void)setTz_origin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)tz_size {
    return self.frame.size;
}

- (void)setTz_size:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(TZOscillatoryAnimationType)type{
    NSNumber *animationScale1 = type == TZOscillatoryAnimationToBigger ? @(1.15) : @(0.5);
    NSNumber *animationScale2 = type == TZOscillatoryAnimationToBigger ? @(0.92) : @(1.15);
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        [layer setValue:animationScale1 forKeyPath:@"transform.scale"];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            [layer setValue:animationScale2 forKeyPath:@"transform.scale"];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                [layer setValue:@(1.0) forKeyPath:@"transform.scale"];
            } completion:nil];
        }];
    }];
}

+ (UIAlertView *) allocPwdInputAlert:(NSString *)msg delegate:(nullable id)delegate{
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:TS("Invalid_Password") message:msg  delegate:delegate cancelButtonTitle:nil otherButtonTitles:TS("Cancel"), TS("OK"), nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    UITextField *tiptextField = [alert textFieldAtIndex:0];
    tiptextField.frame = CGRectMake(0, 0, 200, 10);
    tiptextField.secureTextEntry = YES;
    tiptextField.borderStyle=UITextBorderStyleNone;
    tiptextField.placeholder = TS("Please input password");
    tiptextField.layer.borderColor = [UIColor colorWithRed:36/255.0 green:183/255.0 blue:177/255.0 alpha:1].CGColor;
    tiptextField.layer.cornerRadius = 5;
    return alert;
}

+(void)showUserOrPasswordErrorTips:(int)type delegate:(id)delegate presentedVC:(UIViewController *)vc tag:(int)tag devID:(NSString *)devID changePwd:(BOOL)changePwd{
    
    //判断是否在同一界面，如果不是则不显示
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    if (![currentVC isEqual:vc]) {
        return;
    }
    
    DeviceLoginTipsType realType = TIPS_PWD_ERROR;
    if (type == -11301) {
        realType = TIPS_PWD_ERROR;
    }else if (type == -11302){
        realType = TIPS_USER_ERROR;
    }
    
    if (!devID) {
        devID = @"";
    }
    
    DeviceLoginTipsManager *manager = [DeviceLoginTipsManager shareInstance];
    [manager addTipsInfo:realType devID:devID channel:-1 changePwd:changePwd];
    manager.TipsManagerClickCancelAction = ^{
        if (delegate && [delegate respondsToSelector:@selector(xmAlertVCClickIndex:tag:content:msg:name:)]) {
            [delegate xmAlertVCClickIndex:0 tag:tag content:@"" msg:@"" name:@""];
        }
    };
    
    manager.TipsManagerClickOKAction = ^(NSString * _Nonnull user, NSString * _Nonnull password) {
        if (delegate && [delegate respondsToSelector:@selector(xmAlertVCClickIndex:tag:content:msg:name:)]) {
            [delegate xmAlertVCClickIndex:1 tag:tag content:password msg:@"" name:user];
        }
    };
    
    manager.TipsManagerClickFindPwdAction = ^{
        if (delegate && [delegate respondsToSelector:@selector(xmAlertVCClickIndex:tag:content:msg:name:)]) {
            [delegate xmAlertVCClickIndex:2 tag:tag content:@"" msg:@"" name:@""];
        }
    };
    
    [manager nextTips];
}

//获取当前显示的vc
+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC
{
    UIViewController *currentVC;

    if ([rootVC presentedViewController]) {
        // 视图是被presented出来的

        rootVC = [rootVC presentedViewController];
    }

    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController

        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];

    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController

        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];

    }
    else {
        // 根视图为非导航类

        currentVC = rootVC;
    }

    return currentVC;
}

@end
