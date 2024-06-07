//
//  DeviceAudioPlayManager.m
//  XWorld_General
//
//  Created by Tony Stark on 20/09/2019.
//  Copyright © 2019 xiongmaitech. All rights reserved.
//

#import "DeviceAudioPlayManager.h"
#import <FunSDK/FunSDK.h>
//#import "SVProgressHUD+style.h"
//#import "SDKParser.h"

@interface DeviceAudioPlayManager ()

@property (nonatomic,assign) int msgHandle;

@property (nonatomic,copy) NSString *devID;
@property (nonatomic,assign) BOOL needTryAgain;

@end

@implementation DeviceAudioPlayManager

- (instancetype)init{
    self = [super init];
    if (self) {
        self.msgHandle = FUN_RegWnd((__bridge void*)self);
    }
    
    return self;
}

- (void)dealloc{
    FUN_UnRegWnd(self.msgHandle);
    self.msgHandle = -1;
}

//MARK: - 播放对应标记的音频
- (void)playAudioSign:(int)sign device:(NSString *)devID completion:(DeviceAudioPlayResult)completion{
    self.deviceAudioPlayResult = completion;
    self.devID = devID;
    
    NSDictionary *dic = @{@"Name":@"OpSpecifyAudio",@"SessionID":@"0x0000000001",@"OpSpecifyAudio":@{@"Cmd":@"PlaySpecifyAudio",@"Arg1":[NSNumber numberWithInt:sign]}};
    NSString *str = [self convertToJsonData:dic];
    char cfg[1024];
    memcpy(cfg, [str cStringUsingEncoding:NSUTF8StringEncoding], 2*[str length]);
    
    FUN_DevCmdGeneral(self.msgHandle, [devID UTF8String], 3020, "OpSpecifyAudio", 4096, 15000,cfg, (int)strlen(cfg) + 1, -1, 110);
}

//MARK: - 获取自定义列表
- (void)requestAudioList:(NSString *)devID completion:(DeviceAudioGetAudioListResult)completion{
    self.deviceAudioGetAudioListResult = completion;
    self.devID = devID;
    
    self.needTryAgain = YES;
    
    [self requestAudioList];
}

- (void)requestAudioList{
    NSDictionary *dic = @{@"Name":@"OpSpecifyAudio",@"SessionID":@"0x0000000001",@"OpSpecifyAudio":@{@"Cmd":@"GetSpecifyAudioList"}};
    NSString *str = [self convertToJsonData:dic];
    char cfg[1024];
    memcpy(cfg, [str cStringUsingEncoding:NSUTF8StringEncoding], 2*[str length]);
    
    FUN_DevCmdGeneral(self.msgHandle, [self.devID UTF8String], 3020, "OpSpecifyAudio", 4096, 15000,cfg, (int)strlen(cfg) + 1, -1, 0);
}

-(NSString *)convertToJsonData:(NSDictionary *)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    //    NSRange range = {0,jsonString.length};
    //    //去掉字符串中的空格
    //    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}

//MARK: - FUNSDK CallBack
//MARK: - OnFunSDKResult
- (void)baseOnFunSDKResult:(MsgContent *)msg{
    switch (msg->id)
    {
        case EMSG_DEV_CMD_EN:
        {
            if (strcmp(msg->szStr, "OpSpecifyAudio") == 0) {
                if (msg->param1 < 0) {
                    if (msg->seq == 110) {
                        if (self.deviceAudioPlayResult) {
                            self.deviceAudioPlayResult(msg->param1);
                        }
                    }else{
                        if (self.needTryAgain) {
                            self.needTryAgain = NO;
                            
                            [self requestAudioList];
                        }else{
                            if (self.deviceAudioGetAudioListResult) {
                                self.deviceAudioGetAudioListResult(msg->param1, [NSArray array]);
                            }
                        }
                        
                    }
                    return;
                }else{
                    if (msg->pObject == NULL) {
                        if (self.needTryAgain) {
                            self.needTryAgain = NO;
                            
                            [self requestAudioList];
                        }else{
                            [SVProgressHUD showErrorWithStatus:TS("TR_Data_Parsing_Failed")];
                            if (self.deviceAudioGetAudioListResult) {
                                self.deviceAudioGetAudioListResult(msg->param1, [NSArray array]);
                            }
                        }
//                        [SVProgressHUD showErrorWithStatus:TS(@"TR_Data_Parsing_Failed")];
//                        if (self.deviceAudioGetAudioListResult) {
//                            self.deviceAudioGetAudioListResult(msg->param1, [NSArray array]);
//                        }
                        return;
                    }
                    NSData *jsonData = [NSData dataWithBytes:msg->pObject length:strlen(msg->pObject)];
                    NSError *error;
                    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
                    if(error){
                        if (self.needTryAgain) {
                            self.needTryAgain = NO;
                            
                            [self requestAudioList];
                        }else{
                            [SVProgressHUD showErrorWithStatus:TS("TR_Data_Parsing_Failed")];
                            if (self.deviceAudioGetAudioListResult) {
                                self.deviceAudioGetAudioListResult(msg->param1, [NSArray array]);
                            }
                        }
//                        [SVProgressHUD showErrorWithStatus:TS(@"TR_Data_Parsing_Failed")];
//                        if (self.deviceAudioGetAudioListResult) {
//                            self.deviceAudioGetAudioListResult(msg->param1, [NSArray array]);
//                        }
                        return;
                    }
                    
                    if ([[jsonDic objectForKey:@"Cmd"] isEqualToString:@"GetSpecifyAudioList"]) {
                        NSArray *array = [jsonDic objectForKey:@"CustomAudioList"];
                        if ([array isMemberOfClass:[NSNull class]]) {
                            array = [NSArray array];
                        }
                        
                        if (self.deviceAudioGetAudioListResult) {
                            self.deviceAudioGetAudioListResult(msg->param1, array);
                        }
                    }else if ([[jsonDic objectForKey:@"Cmd"] isEqualToString:@"PlaySpecifyAudio"]){
                        if (self.deviceAudioPlayResult) {
                            self.deviceAudioPlayResult(msg->param1);
                        }
                    }
                }
                
            }
        }
            break;
        default:
            break;
    }
}

@end
