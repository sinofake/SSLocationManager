//
//  SSLocation.h
//  MapDemo
//
//  Created by zhucuirong on 15/11/14.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SSLocation : NSObject

- (instancetype)initWithCLLocation:(CLLocation *)location;
/**
 *  保留最原始的CLLocation信息
 */
@property (nonatomic, strong, readonly) CLLocation *rawLocation;


///////////////////////////处理后的信息///////////////////////////
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 *  当前定位的行政信息
 */
@property (nonatomic, readonly) CLPlacemark *placemark;

/**
 *  当前位置是否在国外
 */
@property (nonatomic, readonly) BOOL abroad;

/**
 *  当前定位城市，市级别城市(去掉了“市”，eg:北京市 >> 北京)
 */
@property (nonatomic, readonly) NSString *city;

/**
 *  当前定位地址全称，由自己拼接而成
 */
@property (nonatomic, readonly) NSString *address;

/**
 *  当前定位地址全称（去掉了“中国”），为直接读取的数据，但这样读取可能会有重复信息，eg: 北京市朝阳区酒仙桥街道酒仙桥酒仙桥中路
 */
@property (nonatomic, readonly) NSString *formattedAddressLines;

- (void)startReverseGeocodeWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)cancelReverseGeocode;

@end
