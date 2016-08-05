//
//  SSReverseGeocoding.m
//  MapDemo
//
//  Created by zhucuirong on 16/8/2.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

@import Foundation;

@interface NSDictionary (SSSafeAccess)

- (NSString*)ss_stringForKey:(id)key;
- (NSInteger)ss_integerForKey:(id)key;
- (NSDictionary*)ss_dictionaryForKey:(id)key;

@end

@implementation NSDictionary (SSSafeAccess)

- (NSString*)ss_stringForKey:(id)key
{
    id value = [self objectForKey:key];
    if (value == nil || value == [NSNull null])
    {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString*)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    
    return nil;
}

- (NSInteger)ss_integerForKey:(id)key
{
    id value = [self objectForKey:key];
    if (value == nil || value == [NSNull null])
    {
        return 0;
    }
    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])
    {
        return [value integerValue];
    }
    return 0;
}

- (NSDictionary*)ss_dictionaryForKey:(id)key
{
    id value = [self objectForKey:key];
    if (value == nil || value == [NSNull null])
    {
        return nil;
    }
    if ([value isKindOfClass:[NSDictionary class]])
    {
        return value;
    }
    return nil;
}

@end


#import "SSReverseGeocoding.h"
#import <CoreLocation/CoreLocation.h>
#import <APOfflineReverseGeocoding/APReverseGeocoding.h>

typedef void (^SSRequestCompletedBlock)(id __nullable result, NSError * __nullable error);

@interface SSReverseGeocoding ()
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSURLSessionTask *urlSessionTask;

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, assign) SSReverseGeocodingStrategy strategy;
@property (nonatomic, copy) SSReverseGeocodeBlock reverseGeocodeBlock;

@end

@implementation SSReverseGeocoding

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    return self;
}

- (void)reverseGeocodeLocation:(CLLocation *)location strategy:(SSReverseGeocodingStrategy)strategy completionHandler:(SSReverseGeocodeBlock)block {
    self.location = location;
    self.strategy = strategy;
    self.reverseGeocodeBlock = block;
    
    switch (strategy) {
        case SSReverseGeocodingApple: {
            [self startAppleReverseGeocode];
            break;
        }
        case SSReverseGeocodingBaidu: {
            [self startBaiduReverseGeocode];
            break;
        }
        case SSReverseGeocodingFirstBaiduLastApple: {
            [self startBaiduReverseGeocode];
            break;
        }
        case SSReverseGeocodingAppleBaiduConcurrently: {
            [self startAppleReverseGeocode];
            [self startBaiduReverseGeocode];
            break;
        }
    }
}

#pragma mark - 苹果反地理编码
- (void)startAppleReverseGeocode {
    [self.geocoder reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks,NSError *error) {
        if (error) {
            [self handleAppleReverseGeocodeFailureWithError:error];
            return;
        }
        
        // 取得第一个地标，一个地名可能搜索出多个地址
        CLPlacemark *placemark  = [placemarks firstObject];

        SSAddress *address      = [[SSAddress alloc] init];
        address.wgs84coordinate = self.location.coordinate;
        address.country         = placemark.country;
        address.province        = placemark.administrativeArea;
        address.district        = placemark.subLocality;
        address.street          = placemark.thoroughfare;
        address.streetNumber    = placemark.subThoroughfare;

        NSString *formattedAddressLines = [placemark.addressDictionary[@"FormattedAddressLines"] componentsJoinedByString:@""];
        if ([formattedAddressLines hasPrefix:@"中国"]) {
            formattedAddressLines = [formattedAddressLines substringFromIndex:2];
        }
        address.formattedAddress = formattedAddressLines;
        
        NSString *city = placemark.locality;
        if (!city) {
            city = placemark.subAdministrativeArea;
        }
        if (!city) {
            city = placemark.administrativeArea;
        }
        address.city = city;
        
        if (self.reverseGeocodeBlock) {
            self.reverseGeocodeBlock(address, nil);
            self.reverseGeocodeBlock = nil;
        }
    }];
}

- (void)handleAppleReverseGeocodeFailureWithError:(NSError *)error {
    if (self.strategy == SSReverseGeocodingAppleBaiduConcurrently) {
        if (self.urlSessionTask.state != NSURLSessionTaskStateRunning) {
            [self callReverseGeocodeBlockWithError:error];
        }
    } else {
        [self callReverseGeocodeBlockWithError:error];
    }
}

#pragma mark - 百度反地理编码
- (void)startBaiduReverseGeocode {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.baiduAppKey forKey:@"ak"];
    [params setValue:self.baiduMcode forKey:@"mcode"];
    [params setObject:@"renderReverse" forKey:@"callback"];
    [params setObject:@"wgs84ll" forKey:@"coordtype"];
    [params setObject:@"json" forKey:@"output"];
    [params setObject:@"0" forKey:@"pois"];
    
    NSString *location = [NSString stringWithFormat:@"%.6f,%.6f", self.location.coordinate.latitude, self.location.coordinate.longitude];
    [params setObject:location forKey:@"location"];
    
    __weak __typeof(self)weakSelf = self;
    self.urlSessionTask = [self requestWithUrl:[NSURL URLWithString:@"http://api.map.baidu.com/geocoder/v2/"] mehtod:@"GET" params:params complated:^(id  _Nullable result, NSError * _Nullable error) {
        __strong __typeof(weakSelf)strongSelf = self;
        
        if (error) {
            [strongSelf handleBaiduReverseGeocodeFailureWithError:error];
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *)result;
        
        NSInteger status = [jsonDict ss_integerForKey:@"status"];
        if (status == 0) {
            NSDictionary *subJsonDict = [jsonDict ss_dictionaryForKey:@"result"];
            NSDictionary *addressComponent = [subJsonDict ss_dictionaryForKey:@"addressComponent"];
            
            SSAddress *address       = [[SSAddress alloc] init];
            address.wgs84coordinate  = strongSelf.location.coordinate;
            address.formattedAddress = [subJsonDict ss_stringForKey:@"formatted_address"];
            address.business         = [subJsonDict ss_stringForKey:@"business"];
            address.country          = [addressComponent ss_stringForKey:@"country"];
            address.province         = [addressComponent ss_stringForKey:@"province"];
            address.city             = [addressComponent ss_stringForKey:@"city"];
            address.district         = [addressComponent ss_stringForKey:@"district"];
            address.street           = [addressComponent ss_stringForKey:@"street"];
            address.streetNumber     = [addressComponent ss_stringForKey:@"street_number"];
            address.direction        = [addressComponent ss_stringForKey:@"direction"];
            address.distance         = [addressComponent ss_stringForKey:@"distance"];
            address.adcode           = [addressComponent ss_stringForKey:@"adcode"];
            address.countryCode      = [addressComponent ss_integerForKey:@"country_code"];
            
            if (strongSelf.reverseGeocodeBlock) {
                strongSelf.reverseGeocodeBlock(address, nil);
                strongSelf.reverseGeocodeBlock = nil;
            }
            return;
        }
        
        NSString *errorDescription;
        if (status == 1) {
            errorDescription = @"服务器内部错误";
        } else if (status == 2) {
            errorDescription = @"请求参数非法";
        } else if (status == 3) {
            errorDescription = @"权限校验失败";
        } else if (status == 4) {
            errorDescription = @"配额校验失败";
        } else if (status == 5) {
            errorDescription = @"ak不存在或者非法";
        } else if (status == 101) {
            errorDescription = @"服务禁用";
        } else if (status == 102) {
            errorDescription = @"不通过白名单或者安全码不对";
        } else if (status < 300) {
            errorDescription = @"无权限";
        } else if (status < 400) {
            errorDescription = @"配额错误";
        } else {
            errorDescription = @"百度反地理编码未知错误";
        }
        
        [strongSelf handleBaiduReverseGeocodeFailureWithError:[NSError errorWithDomain:@"baidu_error_domain" code:status userInfo:@{NSLocalizedDescriptionKey: errorDescription}]];
    }];
}

- (void)handleBaiduReverseGeocodeFailureWithError:(NSError *)error {
    if (self.strategy == SSReverseGeocodingFirstBaiduLastApple) {
        [self startAppleReverseGeocode];
    } else if (self.strategy == SSReverseGeocodingAppleBaiduConcurrently) {
        if (!self.geocoder.isGeocoding) {
            [self callReverseGeocodeBlockWithError:error];
        }
    } else {
        [self callReverseGeocodeBlockWithError:error];
    }
}

- (void)callReverseGeocodeBlockWithError:(NSError *)error {
    if (self.reverseGeocodeBlock) {
        self.reverseGeocodeBlock(nil, error);
        self.reverseGeocodeBlock = nil;
    }
}

- (void)cancelReverseGeocode {
    [self.geocoder cancelGeocode];
    [self.urlSessionTask cancel];
}

#pragma mark - NSURLSessionTask
- (NSURLSessionTask *)requestWithUrl:(NSURL *)url
              mehtod:(NSString *)method
              params:(NSDictionary *)params
           complated:(SSRequestCompletedBlock)completedBlock
{
    NSURL *completedURL = url;
    if (params && ![@[@"PUT", @"POST"] containsObject:method])
    {
        completedURL = [self url:url appendWithQueryDictionary:params];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:completedURL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json; charset=utf8" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:method];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    if (params && [@[@"PUT", @"POST"] containsObject:method])
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
        if (data)
        {
            [request setHTTPBody:data];
        }
    }
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        id result = nil;
        if (data)
        {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //去除renderReverse&&renderReverse()
            NSRange range = [string rangeOfString:@"renderReverse&&renderReverse("];
            if (range.location != NSNotFound) {
                string = [string substringWithRange:NSMakeRange(range.location + range.length, string.length - range.length - 1)];
            }
            result = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        }
        
        if (completedBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completedBlock(result, error);
            });
        }
    }];
    
    [task resume];
    
    return task;
}

static NSString *urlEncode(id object)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSString stringWithFormat:@"%@", object] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
}
 
- (NSURL *)url:(NSURL *)url appendWithQueryDictionary:(NSDictionary *)params
{
    if (params.count <= 0)
    {
        return url;
    }
    
    NSMutableArray *parts = [NSMutableArray array];
    for (id key in params)
    {
        id value = params[key];
        NSString *part = [NSString stringWithFormat: @"%@=%@", urlEncode(key), urlEncode(value)];
        [parts addObject: part];
    }
    
    NSString *queryString = [parts componentsJoinedByString: @"&"];
    NSString *sep = @"?";
    if (url.query)
    {
        sep = @"&";
    }
    
    return [NSURL URLWithString:[url.absoluteString stringByAppendingFormat:@"%@%@", sep, queryString]];
}

@end

