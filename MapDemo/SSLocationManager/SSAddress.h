//
//  SSAddress.h
//  MapDemo
//
//  Created by zhucuirong on 16/8/2.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SSAddress : NSObject
/** 坐标 */
@property (nonatomic, assign) CLLocationCoordinate2D wgs84coordinate;

/** 结构化地址信息 */
@property (nonatomic, copy) NSString *formattedAddress;

/** 国家 */
@property (nonatomic, copy) NSString *country;
/** 省名 */
@property (nonatomic, copy) NSString *province;
/** 城市名 */
@property (nonatomic, copy) NSString *city;
/** 区县名 */
@property (nonatomic, copy) NSString *district;
/** 街道名 */
@property (nonatomic, copy) NSString *street;
/** 街道门牌号 */
@property (nonatomic, copy) NSString *streetNumber;


/////////////////////苹果解析没有下面的值////////////
/** 所在商圈信息，如 "人民大学,中关村,苏州街" */
@property (nonatomic, copy) NSString *business;
/** 和当前坐标点的方向，当有门牌号的时候返回数据 */
@property (nonatomic, copy) NSString *direction;
/** 和当前坐标点的距离，当有门牌号的时候返回数据 */
@property (nonatomic, copy) NSString *distance;
/** 行政区划代码 */
@property (nonatomic, copy) NSString *adcode;
/** 国家代码 */
@property (nonatomic, assign) NSInteger countryCode;
/////////////////////END/////////////////////////


@end
