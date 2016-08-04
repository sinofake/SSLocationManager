//
//  SSLocationManagerDefine.h
//  MapDemo
//
//  Created by zhucuirong on 16/8/4.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#ifndef SSLocationManagerDefine_h
#define SSLocationManagerDefine_h

#import <INTULocationManager/INTULocationRequestDefines.h>
#import "SSAddress.h"


typedef NS_ENUM(NSInteger, SSReverseGeocodingStrategy) {
    SSReverseGeocodingApple,//苹果反地理编码
    SSReverseGeocodingBaidu,//百度反地理编码
    SSReverseGeocodingFirstBaiduLastApple,//先百度，如果百度失败则使用苹果服务
    SSReverseGeocodingAppleBaiduConcurrently//百度苹果同时进行，谁先成功就使用谁的结果
};

static NSString *INTULocationStatusNames[] = {
    [INTULocationStatusSuccess]               = @"定位成功",
    [INTULocationStatusTimedOut]              = @"定位超时",
    [INTULocationStatusServicesNotDetermined] = @"你没有响应定位授权框",
    [INTULocationStatusServicesDenied]        = @"当前应用不能访问定位服务",
    [INTULocationStatusServicesRestricted]    = @"定位服务受到限制",
    [INTULocationStatusServicesDisabled]      = @"当前设备的定位服务已关闭",
    [INTULocationStatusError]                 = @"定位出错"
};

typedef void(^SSLocationRequestBlock)(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status, NSString *statusDescription);

typedef void(^SSReverseGeocodeBlock)(SSAddress *address, NSError *error);


#endif /* SSLocationManagerDefine_h */
