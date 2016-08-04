//
//  SSLocationManager.h
//  MapDemo
//
//  Created by zhucuirong on 16/8/2.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#import <INTULocationManager/INTULocationManager.h>
#import <APOfflineReverseGeocoding/APCountry.h>
#import "SSLocationManagerDefine.h"

@interface SSLocationManager : INTULocationManager
/** 定位请求超时时间, default 15s*/
@property (nonatomic, assign) NSTimeInterval defaultLocationTimeout;

///////////////////百度地理反编码使用////////////
/** 从百度申请的 ak */
@property (nonatomic, copy) NSString *baiduAppKey;
/** 百度创建应用时对应的 Bundle Identifier */
@property (nonatomic, copy) NSString *baiduMcode;
///////////////////END////////////////////////


/** 最近一次的经纬度 */
@property (nonatomic, readonly) CLLocationCoordinate2D lastWgs84coordinate;
/** 国家或地区信息 */
@property (nonatomic, readonly) APCountry *country;
/** 地址信息 */
@property (nonatomic, readonly) SSAddress *address;
/** 是否处于大陆 */
@property (nonatomic, readonly) BOOL inMainland;


- (INTULocationRequestID)requestLocationWithDesiredAccuracy:(INTULocationAccuracy)desiredAccuracy locationBlock:(SSLocationRequestBlock)locationBlock reverseGeocodeBlock:(SSReverseGeocodeBlock)reverseGeocodeBlock;

@end
