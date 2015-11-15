//
//  MapNavModel.h
//  MapDemo
//
//  Created by zhucuirong on 15/11/14.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MapNavType) {
    MapNavTypeAmap,
    MapNavTypeBaidu,
    MapNavTypeTencent,
    MapNavTypeGoogle,
    MapNavTypeApple
};

static NSString *MapNavNames[] = {
    [MapNavTypeAmap]    = @"高德地图",
    [MapNavTypeBaidu]   = @"百度地图",
    [MapNavTypeTencent] = @"腾讯地图",
    [MapNavTypeGoogle]  = @"Google Maps",
    [MapNavTypeApple]   = @"苹果自带地图"
};

@interface MapNavModel : NSObject
@property (nonatomic, assign) MapNavType type;
@property (nonatomic, readonly) NSString *typeName;

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *title;

@end
