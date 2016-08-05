//
//  SSAddress.m
//  MapDemo
//
//  Created by zhucuirong on 16/8/2.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#import "SSAddress.h"

@implementation SSAddress

- (NSString*)description {
    NSMutableString *text = [NSMutableString stringWithFormat:@"<%@> \n", [self class]];
    
    [text appendFormat:@"   [wgs84coordinate]: %f, %f\n", self.wgs84coordinate.latitude, self.wgs84coordinate.longitude];
    [text appendFormat:@"   [formattedAddress]: %@\n", self.formattedAddress];
    [text appendFormat:@"   [country]: %@\n", self.country];
    [text appendFormat:@"   [province]: %@\n", self.province];
    [text appendFormat:@"   [city]: %@\n", self.city];
    [text appendFormat:@"   [district]: %@\n", self.district];
    [text appendFormat:@"   [street]: %@\n", self.street];
    [text appendFormat:@"   [streetNumber]: %@\n", self.streetNumber];
    [text appendFormat:@"   [business]: %@\n", self.business];
    [text appendFormat:@"   [direction]: %@\n", self.direction];
    [text appendFormat:@"   [distance]: %@\n", self.distance];
    [text appendFormat:@"   [adcode]: %@\n", self.adcode];
    [text appendFormat:@"   [countryCode]: %ld\n", (long)self.countryCode];

    [text appendFormat:@"</%@>", [self class]];
    return text;
}

@end
