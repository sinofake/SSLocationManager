//
//  SSReverseGeocoding.h
//  MapDemo
//
//  Created by zhucuirong on 16/8/2.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSLocationManagerDefine.h"

@class CLLocation;

@interface SSReverseGeocoding : NSObject

/** 从百度申请的 ak */
@property (nonatomic, copy) NSString *baiduAppKey;
/** 百度创建应用时对应的 Bundle Identifier */
@property (nonatomic, copy) NSString *baiduMcode;

- (void)reverseGeocodeLocation:(CLLocation *)location strategy:(SSReverseGeocodingStrategy)strategy completionHandler:(SSReverseGeocodeBlock)block;

- (void)cancelReverseGeocode;

@end

