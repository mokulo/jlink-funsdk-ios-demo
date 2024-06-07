# jlink-funsdk-iOS-demo

#### 介绍
# 简介
## 1.概述

FunSDK是专门用于连接监控设备的软件开发工具包（SDK）。FunSDKDemo通过提供丰富的组件和示例代码，使开发者能够迅速实现移动应用对智能视频类设备的连接、控制，并支持丰富的智能场景应用。其主要功能包括设备发现和连接、视频流处理、设备控制、事件处理以及对云服务的支持。通过这些功能，开发者可以轻松地构建具备监控设备连接、控制和智能场景应用功能的移动应用。

## 2.业务架构体系

### 2.1 核心模块

[账号管理](https://docs.jftech.com/docs?menusId=ab0ed73834f54368be3e375075e27fb2&siderid=1710afc548e74c589234c700a4180440)、[设备管理](https://docs.jftech.com/docs?menusId=ab0ed73834f54368be3e375075e27fb2&siderid=06a15009e3f14e79b899006b6f258e23)、[云服务](https://docs.jftech.com/docs?menusId=ab0ed73834f54368be3e375075e27fb2&siderid=1bcfba24806a4c18bb41f2535edb9c42)等

### 2.2 开发工具

SDK最低开发环境：Macos12；      Xcode12；     iOS11；
SDK最高开发环境：SDK会随着开发环境的更新实时更新，请尽量使用最新环境开发

### 2.3 开发语言
SDK库支持C++和Objective-C语言，因为SDK使用C++开发，不支持Swift在中直接使用，因此在Swift中使用时，需要创建Objective-C桥接类，在Objective-C文件中调用SDK接口，在Swift中调用Objective-C类才能实现SDK功能

### 2.4 SDK业务逻辑
![](https://obs-xm-pub.obs.cn-south-1.myhuaweicloud.com/docs/20240124/1706084284719.png)


## 3.SDK功能构成
![](https://obs-xm-pub.obs.cn-south-1.myhuaweicloud.com/docs/20240118/1705545966985.jpg)

## 4.开发者须知

使用序列号访问时，需要先申请开发者鉴权账户。
步骤：
- 第一步：注册开放[开放平台账号](https://aops.jftech.com/#/product)
![](https://obs-xm-pub.obs.cn-south-1.myhuaweicloud.com/docs/20240112/1705042452309.png)
- 第二步：申请应用
  应用审核成功后，进入应用详情页面。获取调用所需的APPUUID，APPKEY，APPSECRET，MOVECARD参数
![](https://obs-xm-pub.obs.cn-south-1.myhuaweicloud.com/docs/20240408/1712554597279.png)

- 第三步：在[SDK初始化](https://docs.jftech.com/docs?menusId=ab0ed73834f54368be3e375075e27fb2&siderid=6caa41621abd4e689b21a3c0339e8cd6)时填入相应参数
FUN_XMCloundPlatformInit(APPUUID, APPKEY, APPSECRET, MOVECARD);