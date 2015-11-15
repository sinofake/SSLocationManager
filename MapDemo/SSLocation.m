//
//  SSLocation.m
//  MapDemo
//
//  Created by zhucuirong on 15/11/14.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import "SSLocation.h"
#import <AddressBook/AddressBook.h>

static inline double transformLatitude(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}

static inline double transformLongitude(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}

static inline void WGS84ToGCJ_02WithLatitudeLongitude(double *lat, double *lon) {
    const double a = 6378245.0f;
    const double ee = 0.00669342162296594323;
    
    double dLat = transformLatitude(*lon - 105.0, *lat - 35.0);
    double dLon = transformLongitude(*lon - 105.0, *lat - 35.0);
    double radLat = *lat / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * M_PI);
    *lat = *lat + dLat;
    *lon = *lon + dLon;
}

static inline BOOL outOfChina(double lat, double lon) {
    if (lon < 72.004 || lon > 137.8347)
        return YES;
    if (lat < 0.8293 || lat > 55.8271)
        return YES;
    return NO;
}

// 判断字符串是否有值
#define SS_STRINGHASVALUE(str)     (str && [str isKindOfClass:[NSString class]] && [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0)

@interface SSLocation ()
@property (nonatomic, strong) CLLocation *rawLocation;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) CLPlacemark *placemark;
@property (nonatomic, assign) BOOL abroad;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *formattedAddressLines;
@property (nonatomic, strong) CLGeocoder *geocoder;

/**
 *  反地理编码后的回调
 */
@property (nonatomic, copy) void(^reverseGeocodeCompletionHandler)(NSError *error);

@end


@implementation SSLocation

- (instancetype)initWithCLLocation:(CLLocation *)location {
    if (self = [super init]) {
        self.rawLocation = location;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.coordinate = self.rawLocation.coordinate;
    
    double lat = self.coordinate.latitude;
    double lon = self.coordinate.longitude;
    // 把坐标点范围锁定在国内，排除国外的情况
    if (!outOfChina(lat, lon)) {
        // 纠偏处理 火星坐标
        WGS84ToGCJ_02WithLatitudeLongitude(&lat, &lon);
        self.coordinate = CLLocationCoordinate2DMake(lat, lon);
    }
}

- (void)startReverseGeocodeWithCompletionHandler:(void(^)(NSError *error))completionHandler {
    self.reverseGeocodeCompletionHandler = completionHandler;
    [self startReverseGeocode];
}

- (void)startReverseGeocode {
    self.geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude];
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks,NSError *error) {
        if (error) {
            NSLog(@"位置反编码失败， error:%@", error.localizedDescription);
        }
        // 取得第一个地标，地标中存储了详细的地址信息，注意：一个地名可能搜索出多个地址
        CLPlacemark *placemark = [placemarks firstObject];
        self.placemark = placemark;
        
        if ([placemark.ISOcountryCode isEqualToString:@"CN"]) {
            // 中国大陆
            self.abroad = NO;
        }
        else if ([placemark.ISOcountryCode  isEqualToString:@"TW"]
                 || [placemark.ISOcountryCode  isEqualToString:@"HK"]
                 || [placemark.ISOcountryCode  isEqualToString:@"MO"]) {
            //中国台湾、中国香港、中国澳门
            self.abroad = NO;
            self.coordinate = self.rawLocation.coordinate;
        }
        else {
            // 国外
            self.abroad = YES;
            self.coordinate = self.rawLocation.coordinate;
        }
        
        // 省 eg:北京市、湖南省
        NSString *administrativeArea = placemark.administrativeArea;
        //使用系统定义的字符串直接查询，记得导入AddressBook框架
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (!SS_STRINGHASVALUE(administrativeArea)) {
            administrativeArea = SS_STRINGHASVALUE(placemark.addressDictionary[(NSString *)kABPersonAddressStateKey]) ? placemark.addressDictionary[(NSString *)kABPersonAddressStateKey] : @"";
        }
        
        // 市 eg:北京市市辖区、长沙市
        NSString *locality = placemark.locality;
        if (!SS_STRINGHASVALUE(locality)) {
            locality = SS_STRINGHASVALUE(placemark.addressDictionary[(NSString *)kABPersonAddressCityKey]) ? placemark.addressDictionary[(NSString *)kABPersonAddressCityKey] : @"";
        }
#pragma clang diagnostic pop
        
        self.city = SS_STRINGHASVALUE(locality) ? locality : administrativeArea;
        
        // 区 eg:朝阳区
        NSString *subLocality = SS_STRINGHASVALUE(placemark.subLocality) ? placemark.subLocality : @"";
        
        // 街道 eg:酒仙桥中路
        NSString *thoroughfare = SS_STRINGHASVALUE(placemark.thoroughfare) ? placemark.thoroughfare : @"";
        
        //subThoroughfare为街道相关信息、例如门牌等 eg: 6878号
        if (SS_STRINGHASVALUE(placemark.subThoroughfare)) {
            thoroughfare = [thoroughfare stringByAppendingString:placemark.subThoroughfare];
        }
        
        //位置名 可能是建筑物名称(eg:星科大厦)，也有可能是地址全称(eg:中国上海市黄浦区南京东路街道人民广场延安东路)
        NSString *name = SS_STRINGHASVALUE(placemark.name) ? placemark.name : @"";
        
        if (SS_STRINGHASVALUE(thoroughfare) && [name hasSuffix:thoroughfare]) {
            //如果name是地址全称，将其置空
            name = @"";
        }
        else {
            NSArray *array = @[@"中国", administrativeArea, locality, subLocality];
            //去看name中的行政信息
            for (NSString *string in array) {
                if ([name hasPrefix:string]) {
                    name = [name substringFromIndex:[name rangeOfString:string].length];
                }
            }
        }
        
        //直辖市处理 eg: administrativeArea:北京市 locality:北京市市辖区
        if ([locality hasSuffix:@"市市辖区"]) {
            locality = @"";
        }
        self.address = [NSString stringWithFormat:@"%@%@%@%@%@", administrativeArea, locality, subLocality, thoroughfare, name];
        
        //NSArray * allKeys = placemark.addressDictionary.allKeys;
        //for (NSString * key in allKeys) {
        //NSLog(@"key = %@, value = %@", key, placemark.addressDictionary[key]);
        //}
        self.formattedAddressLines = [placemark.addressDictionary[@"FormattedAddressLines"] componentsJoinedByString:@""];
        if ([self.formattedAddressLines hasPrefix:@"中国"]) {
            self.formattedAddressLines = [self.formattedAddressLines substringFromIndex:2];
        }
        
        if (self.reverseGeocodeCompletionHandler) {
            self.reverseGeocodeCompletionHandler(error);
            self.reverseGeocodeCompletionHandler = nil;
        }
    }];
}

- (void)cancelReverseGeocode {
    if (self.geocoder.isGeocoding) {
        [self.geocoder cancelGeocode];
    }
}

#pragma mark - custom accessor
- (void)setCity:(NSString *)city {
    if (_city == city) {
        return;
    }
    if ([city hasSuffix:@"市市辖区"]) {
        city = [city substringToIndex:([city rangeOfString:@"市市辖区"]).location];
    }
    else if ([city hasSuffix:@"市"]) {
        if (city.length > 2) {
            city = [city substringToIndex:city.length - 1];
        }
    }
    
    if ([city hasPrefix:@"香港"]) {
        city = @"香港";
    }
    else if ([city hasPrefix:@"澳门"] || [city hasPrefix:@"澳門"]) {
        city = @"澳门";
    }
    
    _city = city;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"\n ======原定位信息：======\n <rawLocation:%@>\n ======处理后的信息：====== \n <coordinate:%f, %f>\n <abroad:%@>\n <city:%@>\n <address:%@>\n <formattedAddressLines:%@>\n", self.rawLocation, self.coordinate.latitude, self.coordinate.longitude, self.abroad ? @"YES": @"NO", self.city, self.address, self.formattedAddressLines];
}


@end
