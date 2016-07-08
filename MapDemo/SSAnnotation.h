//
//  SSAnnotation.h
//  MapDemo
//
//  Created by zhucuirong on 16/7/4.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface SSAnnotation : NSObject<MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *subtitle;

@end
