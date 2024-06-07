//
//  AddLANCameraViewController.h
//  XMEye
//
//  Created by 杨翔 on 2020/5/20.
//  Copyright © 2020 Megatron. All rights reserved.
//

/*
 对设备进行配网成功之后，已经搜索到设备信息，之后的添加设备流程
 1、先获取设备登录用户名和密码:getDeviceRandomPwd（不支持随机用户名密码的设备，出厂用户名和密码是有固定默认值。支持随机用户名密码的设备，出厂时设备登录用户名和登录密码是随机值。）
 2、设备不支持随机用户名密码流程
 2.1、如果设备不支持随机用户名密码，则getDeviceRandomPwd 回调的是设备通用的默认用户名admin、空密码（可以在APP内转为设备定制的用户名和密码）。
 2.2、用户设置完设备信息点击添加，调用修改设备密码接口，修改设备密码 FUN_DevSetConfig_Json
 2.3、修改设备密码成功之后，进入回调 EMSG_DEV_SET_CONFIG_JSON， 然后添加设备到账号
 2.4、添加设备到账号接口：FUN_SysAdd_Device

 3、设备支持随机用户名密码流程
 3.1、如果设备支持随机用户名密码，则getDeviceRandomPwd 回调的是一组随机的用户名密码信息，添加设备前需要用户设置新的用户名和密码，否则需要记录随机用户名和密码供后续使用（特护情况需要输入密码时客户不知道的话，会登录设备失败）。
 3.2、支持随机用户名密码的设备，getDeviceRandomPwd  可能会同时回调一个设备token，支持token的设备，可以用token登录设备（设备token在局域网时候可以获取，也可以通过用户名密码登录成功之后SDK会自动获取。通过FUN_DevGetLocalEncToken和Fun_DevSetLocalEncToken接口向SDK读取或者写入token，SDK接口会自己使用写入的token。修改设备密码、恢复设备出厂设置时，设备token会重置，因此这些操作需要重新获取设备token）
 3.3、用户设置完设备信息点击添加，调用修改设备密码接口，修改设备密码 FUN_DevSetConfig_Json
 3.4、修改设备密码成功之后，进入回调 EMSG_DEV_SET_CONFIG_JSON， 然后获取设备特征码 requestCloudCryNum
 3.5、获取特征码和绑定状态之后，再获取设备绑定标志，判断设备是否已被其他账号绑定
 3.6、获取到特征码和设备绑定状态之后，APP可以自定逻辑，是执行直接添加流程，还是取消其他设备订阅之后再添加，添加设备时是否需要删除已经添加到其他账号下的本设备等等
 
 备注： 添加设备接口 FUN_SysAdd_Device
 * @brief 接口说明
 * @param pDevInfo SDBDeviceInfo 设备信息
 * @param szExInfo 格式 param1=value1&param2=value2 <p>
 * 其中“ma=true&delOth=true”设置此帐户为此设备的主帐户，且其他的设备列表下删除此设备<p>
 * 其中“ext=XXXXXXXX”设置设备的用户自定义信息      例如：设置第三方设备"ext=DevType_DH";
 * @param szExInfo2 设备token信息 示例：{"AdminToken":"M6NymdA1qfOCXmqXXZ4sF9Qje3RRKkVRF3pbzyKfFUk="}
 * @return @async 消息ID：5004; param1: >=0 成功，否者失败 Str:结果信息(JSON格式) pData:SDBDeviceInfo设备信息
  int FUN_SysAdd_Device(UI_HANDLE hUser, SDBDeviceInfo *pDevInfo, const char *szExInfo = "", const char *szExInfo2 = "", int nSeq = 0);
 
 */

#import "BaseViewController.h"
#import "DeviceObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddLANCameraViewController : BaseViewController

@property (nonatomic, strong) DeviceObject *deviceInfo;


@end

NS_ASSUME_NONNULL_END
