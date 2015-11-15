//
//  NSString+URLEncoding.m
//  MapDemo
//
//  Created by zhucuirong on 15/11/14.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import "NSString+URLEncoding.h"

@implementation NSString (URLEncoding)
- (NSString *)URLEncodedString {
    //!*'();:@&amp;=+$,/?%#[]
    CFStringRef cfResult = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                   (CFStringRef)self,
                                                                   NULL,
                                                                   CFSTR("&=@;!'*#%-,:/()<>[]{}?+ "),
                                                                   kCFStringEncodingUTF8);
    
    NSString *result = [NSString stringWithString:(__bridge NSString *)cfResult];
    CFRelease(cfResult);
    
    return result;
}

- (NSString*)URLDecodedString {
    NSString *result = (NSString *)
    CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                              (CFStringRef)self,
                                                                              CFSTR(""),
                                                                              kCFStringEncodingUTF8));
    return result;
}


@end
