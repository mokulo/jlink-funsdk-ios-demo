# jlink-funsdk-iOS-demo

# Introduction
## 1. Overview
FunSDK is a software development toolkit (SDK) designed specifically for connecting surveillance devices. By providing rich components and sample code, FunSDK enables developers to quickly implement the connection and control of smart video devices in mobile applications, supporting various intelligent scenario applications. Its main functions include device discovery and connection, video stream processing, device control, event handling, and support for cloud services. Through these features, developers can easily build mobile applications with monitoring device connection, control, and intelligent scenario application capabilities.

## 2. Business Architecture System
### 2.1 Core Modules:
 [Account Management](https://docs.jftech.com/docs?menusId=2531aba7e2d84e13ad8ce977007922f3&siderid=bb187c70660941b2b96d78269eb04e40&lang=en&directory=true), [Device Management](https://docs.jftech.com/docs?menusId=2531aba7e2d84e13ad8ce977007922f3&siderid=4e7ce74e08fc4fd2a4f26d7980e58773&lang=en&directory=true), [Cloud Services](https://docs.jftech.com/docs?menusId=2531aba7e2d84e13ad8ce977007922f3&siderid=c16add307c234c14a33f272d420cfdf3&lang=en&directory=false), etc.
### 2.2 Development Tools:
 Macos12；      Xcode12；     iOS11；

### 2.3 Development Language

The SDK library supports C++and Objective-C languages. Because the SDK is developed using C++and does not support Swift''s direct use in, when using in Swift, you need to create Objective-C bridge classes, call the SDK interface in Objective-C files, and call Objective-C classes in Swift to implement SDK functions

## 3. SDK Functional Composition
![](https://obs-xm-pub.obs.cn-south-1.myhuaweicloud.com/docs/20240118/1705545966985.jpg)

## 4. Developer Guidelines
When accessing using a serial number, you need to apply for a developer authentication account.  
Steps:  
- First Step:Register an account on the [Open Platform](https://aops.jftech.com/#/product).  
![](https://obs-xm-pub.obs.cn-south-1.myhuaweicloud.com/docs/20240112/1705042746187.png)

- Second Step:Apply for the application
   After the application is successfully reviewed, go to the application details page. Obtain the required parameters for the API call, including APPUUID, APPKEY, APPSECRET, and MOVECARD.
   ![](https://obs-xm-pub.obs.cn-south-1.myhuaweicloud.com/docs/20240112/1705042834433.png)

- Third Step:[SDK Initialization](https://docs.jftech.com/docs?menusId=ab0ed73834f54368be3e375075e27fb2&siderid=d80a640c5df34d2d964a09ce905cffe4&lang=en&directory=false)
   Fill in the corresponding parameters during SDK initialization.
   FUN_XMCloundPlatformInit(APPUUID, APPKEY, APPSECRET, MOVECARD);