//
//  SSLocationManager.m
//  MapDemo
//
//  Created by zhucuirong on 16/8/2.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#import "SSLocationManager.h"
#import <APOfflineReverseGeocoding/APReverseGeocoding.h>
#import "SSReverseGeocoding.h"

@interface SSLocationManager ()
@property (nonatomic, assign) CLLocationCoordinate2D lastWgs84coordinate;
@property (nonatomic, strong) APCountry *country;
@property (nonatomic, strong) SSAddress *address;
@property (nonatomic, strong) APReverseGeocoding *countryReverseGeocoding;

@end

@implementation SSLocationManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.defaultLocationTimeout = 15.f;
    }
    return self;
}

- (INTULocationRequestID)requestLocationWithDesiredAccuracy:(INTULocationAccuracy)desiredAccuracy locationBlock:(SSLocationRequestBlock)locationBlock reverseGeocodeBlock:(SSReverseGeocodeBlock)reverseGeocodeBlock {
    __weak __typeof(self)weakSelf = self;
    
    return [self requestLocationWithDesiredAccuracy:desiredAccuracy timeout:self.defaultLocationTimeout delayUntilAuthorized:YES block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        if (locationBlock) {
            locationBlock(currentLocation, achievedAccuracy, status, INTULocationStatusNames[status]);
        }
        
        if (status != INTULocationStatusSuccess) {
            return;
        }
        
        strongSelf.lastWgs84coordinate = currentLocation.coordinate;
        
        APCountry *country = [strongSelf.countryReverseGeocoding geocodeCountryWithCoordinate:currentLocation.coordinate];
        strongSelf.country = country;
        
        if (!reverseGeocodeBlock) {
            return;
        }
        
        SSReverseGeocodingStrategy strategy = SSReverseGeocodingApple;
        if (([country.name isEqualToString:@"China"] || [country.name isEqualToString:@"Taiwan"])) {
            strategy = SSReverseGeocodingFirstBaiduLastApple;
        }
        
        SSReverseGeocoding *reverseGeocoding = [[SSReverseGeocoding alloc] init];
        reverseGeocoding.baiduAppKey = strongSelf.baiduAppKey;
        reverseGeocoding.baiduMcode = strongSelf.baiduMcode;
        [reverseGeocoding reverseGeocodeLocation:currentLocation strategy:strategy completionHandler:^(SSAddress *address, NSError *error) {
            if (!error) {
                strongSelf.address = address;
            }
            reverseGeocodeBlock(address, error);
        }];
    }];
}

#pragma mark - custom accessor
- (APReverseGeocoding *)countryReverseGeocoding {
    if (!_countryReverseGeocoding) {
        _countryReverseGeocoding = [APReverseGeocoding defaultGeocoding];
    }
    return _countryReverseGeocoding;
}

- (BOOL)inMainland {
    if ([self.country.name isEqualToString:@"China"]) {
        return YES;
    }
    return NO;
}

@end



