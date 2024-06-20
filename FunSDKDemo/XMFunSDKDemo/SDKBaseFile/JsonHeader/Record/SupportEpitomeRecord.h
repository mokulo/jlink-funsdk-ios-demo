#pragma once
#include "FunSDK/JObject.h"
//缩影录像配置
#define JK_EpitomeRecord "Storage.EpitomeRecord"
class SupportEpitomeRecord : public JObject
{
public:
    JBoolObj        Enable; //使能开关
    JIntObj        Interval; //抽帧间隔  1~86400，单位为秒（最大值为一天）
    JStrObj        StartTime;//开始时间
    JStrObj        EndTime;//结束时间
    
    /*
     "1 00:00:00-24:00:00"，前面的1代表此工作时间段生效，0则不生效；
     最多可配置6个工作时间段；
     当时间表里的时间段和"StartTime""EndTime"有冲突时，以后者为准。
     */
    JObjArray<JObject>        TimeSection; //当天录像工作时间表

public:
    SupportEpitomeRecord(JObject *pParent = NULL, const char *szName = JK_EpitomeRecord):
    JObject(pParent,szName),
    Enable(this, "Enable"),
    Interval(this, "Interval"),
    StartTime(this, "StartTime"),
    EndTime(this, "EndTime"),
    TimeSection(this, "TimeSection"){
    };

    ~SupportEpitomeRecord(void){};
};
