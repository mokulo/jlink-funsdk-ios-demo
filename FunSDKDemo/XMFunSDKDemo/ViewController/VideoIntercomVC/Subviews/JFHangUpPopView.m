//
//  JFHangUpPopView.m
//   iCSee
//
//  Created by kevin on 2023/12/9.
//  Copyright © 2023 xiongmaitech. All rights reserved.
//

#import "JFHangUpPopView.h"

@implementation JFHangUpPopView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self.layer setCornerRadius:10];
        [self.layer setMasksToBounds:YES];
        self.backgroundColor = [UIColor whiteColor];
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self addSubview:self.lblTitle];
    [self addSubview:self.lblSubTitle];
    [self.lblTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(5);
            make.right.mas_equalTo(-5);
            make.top.mas_equalTo(9.5);
//        make.height.mas_equalTo(20);
    }];
    [self.lblSubTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(5);
            make.right.mas_equalTo(-5);
            make.top.mas_equalTo(self.lblTitle.mas_bottom).mas_offset(2);
        make.bottom.mas_equalTo(self.mas_bottom).mas_offset(-9.5);
    }];
}
- (void)showWithTime:(NSString *)timeStr {
    if ([timeStr isEqualToString:@"calloff"]) {
        self.lblSubTitle.text = @"";
    } else {
        self.lblSubTitle.text = [NSString stringWithFormat:@"%@：%@",TS("TR_Video_Call_TalkTime"),timeStr];
    }
}
#pragma mark - **************** lazyload ****************
- (UILabel *)lblTitle {
    if (!_lblTitle) {
        _lblTitle = [[UILabel alloc] init];
        _lblTitle.font = [UIFont systemFontOfSize:14];
        _lblTitle.textColor = [UIColor blackColor];
        _lblTitle.text = TS("TR_Video_Other_Call_Off");
        _lblTitle.numberOfLines = 0;
        _lblTitle.textAlignment = NSTextAlignmentCenter;
    }
    return _lblTitle;
}
- (UILabel *)lblSubTitle {
    if (!_lblSubTitle) {
        _lblSubTitle = [[UILabel alloc] init];
        _lblSubTitle.font = [UIFont systemFontOfSize:10];
        _lblSubTitle.textColor = [UIColor blackColor];
        _lblSubTitle.numberOfLines = 0;
        _lblSubTitle.textAlignment = NSTextAlignmentCenter;

    }
    return _lblSubTitle;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
