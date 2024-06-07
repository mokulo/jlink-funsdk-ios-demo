//
//  VideoIntercomView.m
//  JLink
//
//  Created by 吴江波 on 2023/11/7.
//

#import "VideoIntercomView.h"

@interface VideoIntercomView()<UIGestureRecognizerDelegate>
@end

@implementation VideoIntercomView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self appendSubViews];
    }
    
    return self;
}

-(void)appendSubViews{
    [self addSubview:self.hangUpBtn];
    //挂断
    [self.hangUpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@80);
        make.height.equalTo(@80);
        make.bottom.mas_equalTo(-30);
        make.centerX.equalTo(self);
    }];
    //手机摄像头开关
    [self addSubview:self.phoneShotBtn];
    [self.phoneShotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.height.equalTo(@50);
        make.centerY.equalTo(self.hangUpBtn.mas_centerY);
        make.right.mas_equalTo(-45);
    }];
    
    //手机摄像头切换开关
    [self addSubview:self.phoneShotChangeBtn];
    [self.phoneShotChangeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@80);
        make.height.equalTo(@80);
        make.centerY.equalTo(self.hangUpBtn.mas_centerY);
        make.left.mas_equalTo(45);

    }];
    
    //麦克风按钮
    [self addSubview:self.microphoneBtn];
    [self.microphoneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.hangUpBtn.mas_top).offset(-25.5);
        make.width.equalTo(@75);
        make.height.equalTo(@75);
        make.right.mas_equalTo(-52);
    }];
    
    [self addSubview:self.audioBtn];
    [self.audioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.hangUpBtn.mas_top).offset(-25.5);
        make.width.equalTo(@75);
        make.height.equalTo(@75);
        make.left.mas_equalTo(52);
    }];
    
    [self addSubview:self.videoTimeLab];
    [self.videoTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(NavHeight + 10);
        make.width.equalTo(@200);
        make.height.equalTo(@20);
        make.centerX.equalTo(self);
    }];
    
    self.yuvView = [[YUVPlayer alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 130, 44 + 30, 110,196)];
    [self addSubview:self.yuvView];
}


#pragma mark - action
#pragma mark - 挂断
-(void)hangUpClick{
    if(self.hangUpAction){
        self.hangUpAction();
    }
}

#pragma mark - 手机摄像头开关
-(void)phoneShotClick{
    if(self.phoneShotAction){
        self.phoneShotAction();
    }
}

#pragma mark - 手机摄像头镜头切换开关
-(void)phoneShotChangeClick{
    if(self.phoneShotChangeAction){
        self.phoneShotChangeAction();
    }
}

#pragma mark - 扬声器切换开关
-(void)audioBtnClick{
    if(self.audioAction){
        self.audioAction();
    }
}

#pragma mark - 麦克风切换开关
-(void)microphoneBtnClick{
    if(self.microphoneAction){
        self.microphoneAction();
    }
}

#pragma mark - 刷新麦克风开关状态
-(void)refeshMicroPhoneBtnState:(BOOL)select
{
    self.microphoneBtn.selected = select;
}

#pragma mark - 刷新音频开关状态
-(void)refeshAudioBtnState:(BOOL)select
{
    self.audioBtn.selected = select;
}

#pragma mark - 刷新手机镜头开关状态
-(void)refeshPhoneShotBtnState:(BOOL)select{
    if(select){
        self.phoneShotBtn.selected = YES;
    }else{
        self.phoneShotBtn.selected = NO;
    }
}
#pragma mark - 刷新手机前后镜头开关状态
-(void)refeshPhoneShotChangeBtnState:(BOOL)isBackgroundCamera{
    self.phoneShotChangeBtn.selected = isBackgroundCamera;
}
#pragma mark - 对讲初始化完成。按钮变成可点击
-(void)videoTalkInitSuccess{
    self.phoneShotBtn.enabled = YES;
    self.phoneShotChangeBtn.enabled = YES;
    [self.phoneShotChangeBtn setTitle: @"前置" forState:UIControlStateNormal];
    
    self.microphoneBtn.enabled = YES;
    [self.microphoneBtn setImage:[UIImage imageNamed:@"talk_unselect.png"] forState:UIControlStateNormal];
    
    self.audioBtn.enabled = YES;
    [self.audioBtn setImage:[UIImage imageNamed:@"btn_voice_normal.png"] forState:UIControlStateNormal];
    
}

#pragma mark - lazyload
-(UIButton *)hangUpBtn{
    if(!_hangUpBtn){
        _hangUpBtn = [[UIButton alloc] init];
        [_hangUpBtn setTitle: @"挂断" forState: UIControlStateNormal];
        [_hangUpBtn addTarget:self action:@selector(hangUpClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _hangUpBtn;
}



-(UIButton *)phoneShotBtn{
    if(!_phoneShotBtn){
        _phoneShotBtn = [[UIButton alloc] init];
        _phoneShotBtn.enabled = NO;
        [_phoneShotBtn setTitle: @"摄像头" forState: UIControlStateNormal];
        [_phoneShotBtn addTarget:self action:@selector(phoneShotClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _phoneShotBtn;
}


-(UIButton *)phoneShotChangeBtn{
    if(!_phoneShotChangeBtn){
        _phoneShotChangeBtn = [[UIButton alloc] init];
        _phoneShotChangeBtn.enabled = NO;
        [_phoneShotChangeBtn setTitle: @"前置" forState: UIControlStateNormal];
        [_phoneShotChangeBtn setTitle: @"后置" forState: UIControlStateSelected];
        [_phoneShotChangeBtn addTarget:self action:@selector(phoneShotChangeClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _phoneShotChangeBtn;
}


-(UIButton *)microphoneBtn{
    if(!_microphoneBtn){
        _microphoneBtn = [[UIButton alloc] init];
        _microphoneBtn.enabled = NO;
        [_microphoneBtn setImage:[UIImage imageNamed:@"talk_unselect.png"] forState:UIControlStateNormal];
        //[_microphoneBtn setBackgroundImage:[UIImage imageNamed:@"videotalk_mic_close.png"] forState:UIControlStateNormal];
        [_microphoneBtn setImage:[UIImage imageNamed:@"talk_select.png"] forState:UIControlStateSelected];
        [_microphoneBtn addTarget:self action:@selector(microphoneBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _microphoneBtn;
}

-(UIButton *)audioBtn{
    if(!_audioBtn){
        _audioBtn = [[UIButton alloc] init];
        _audioBtn.enabled = NO;
//        [_audioBtn setBackgroundImage:[UIImage imageNamed:@"videotalk_sound_uninit.png"] forState:UIControlStateNormal];
        [_audioBtn setImage:[UIImage imageNamed:@"btn_voice_normal.png"] forState:UIControlStateNormal];
        [_audioBtn setImage:[UIImage imageNamed:@"btn_voice_selected.png"] forState:UIControlStateSelected];
        [_audioBtn addTarget:self action:@selector(audioBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _audioBtn;
}


-(UILabel *)deviceNameLab{
    if(!_deviceNameLab){
        _deviceNameLab = [[UILabel alloc] init];
        _deviceNameLab.text = TS(@"");
        _deviceNameLab.textColor = [UIColor whiteColor];
        _deviceNameLab.font = [UIFont systemFontOfSize:17];
        _deviceNameLab.numberOfLines = 2;
    }
    
    return _deviceNameLab;
}


-(YUVPlayer *)yuvView{
    if(!_yuvView){
        _yuvView = [[YUVPlayer alloc] init];
    }
    
    return _yuvView;
}

@end
