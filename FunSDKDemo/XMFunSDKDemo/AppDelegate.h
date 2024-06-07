//
//  AppDelegate.h
//  XMFamily
//
//  Created by VladDracula on 18-3-4.
//  Copyright (c) 2018年 ___FULLUSERNAME___. All rights reserved.
//
/***
 
 声明： 开发环境：Macos：10.13.6     Xcode：9.4.1
 
 重点说明：
 程序中初始化APP信息的方法：FUN_XMCloundPlatformInit(UUID, APPKEY, APPSECRET, MOVECARD);
 其中四个参数，需要在"雄迈开放平台"上面注册登录，然后在"应用中心"添加应用来获取，每一个应用对应一组不同并且唯一的平台信息，不能重复，如果直接使用Demo中的参数，可能会造成各种问题
 雄迈开放平台网址：http://open.xmeye.net/
 
 1、如果想要简单快速开发，并且没有定制服务器和其他特殊的功能，那么可以直接重新开发ViewController，按照demo中的       调用方式直接调用各个功能的Manager和Control等功能类。
 2、如果有定制服务器和其他特殊功能，则可能需要根据定制内容进行一些修改(例如替换支持定制内容的底层库等等)
 3、如果是demo中没有的功能，首先可以根据协议尝试自己开发，如果无法实现则可以联系我们，由我们来判断是否需要在demo中添加此功能 。
 4、如果在开发过程中发现本应该进入的回调方法未调用，请检查：1、没有初始化SDK。2、接口或参数异常。3、接口所在函数被释放。4、回调方法写错
 5、替换自己的证书时，请注意证书权限，需要包括 Push Notifications（推送功能），Access WiFi Information（Wifi信息配网功能），Multicast Networking（配网功能）等等
 *****/
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, copy) void (^testBlock)(int index); //index回调
@property (strong, nonatomic) UIWindow *window;



@end
