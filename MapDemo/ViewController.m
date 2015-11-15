//
//  ViewController.m
//  MapDemo
//
//  Created by zhucuirong on 15/11/14.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import "ViewController.h"
#import <INTULocationManager.h>
#import "SSLocation.h"
#import "NSString+URLEncoding.h"
#import "MapNavModel.h"
#import <MapKit/MapKit.h>
#import "MapViewController.h"
#import <AMapLocationKit/AMapLocationKit.h>

@interface ViewController ()<UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) SSLocation *location;
@property (nonatomic, assign) CLLocationCoordinate2D tocoord;
@property (nonatomic, copy) NSString *toTitle;
@property (nonatomic, strong) NSArray *navModels;

@property (nonatomic, strong) AMapLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /**
     北京饭店:
     (CLLocationCoordinate2D) ccld = (latitude = 39.909250999999998, longitude = 116.410599)
     
     北京昆泰酒店:
     (CLLocationCoordinate2D) ccld = (latitude = 40.005034670999997, longitude = 116.490526199)
     
     北京亚奥国际酒店:
     (CLLocationCoordinate2D) ccld = (latitude = 40.000906209999997, longitude = 116.3716328)
     */
    self.tocoord = CLLocationCoordinate2DMake(40.005034, 116.490526);
    self.toTitle = @"北京昆泰酒店";
    
    [AMapLocationServices sharedServices].apiKey = @"edcd8c0f9822842d005cf2fe4b516461";
}

- (NSString *)getErrorDescription:(INTULocationStatus)status {
    if (status == INTULocationStatusServicesNotDetermined) {
        return @"Error: User has not responded to the permissions alert.";
    }
    if (status == INTULocationStatusServicesDenied) {
        return @"Error: User has denied this app permissions to access device location.";
    }
    if (status == INTULocationStatusServicesRestricted) {
        return @"Error: User is restricted from using location services by a usage policy.";
    }
    if (status == INTULocationStatusServicesDisabled) {
        return @"Error: Location services are turned off for all apps on this device.";
    }
    return @"An unknown error occurred.\n(Are you using iOS Simulator with location set to 'None'?)";
}

- (IBAction)startLocationAction:(id)sender {
    __weak __typeof(self)weakSelf = self;

    self.locationManager = [[AMapLocationManager alloc] init];
    // 带逆地理（返回坐标和地址信息）
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            weakSelf.statusLabel.text = [NSString stringWithFormat:@"locError:{%ld - %@};", (long)error.code, error.localizedDescription];
            if (error.code == AMapLocationErrorReGeocodeFailed)
            {
                return;
            }
        }
        
        NSLog(@"location:%@", location);
        
        if (regeocode)
        {
            NSLog(@"reGeocode:%@", regeocode);
        }
        
        weakSelf.statusLabel.text = [NSString stringWithFormat:@"location:%@, reGeocode:%@", location, regeocode];
    }];
    
    return;
    
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyCity
                                                                timeout:10
                                                   delayUntilAuthorized:YES
                                                                  block:
                              ^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                  __typeof(weakSelf) strongSelf = weakSelf;
                                  
                                  if (status == INTULocationStatusSuccess) {
                                      // achievedAccuracy is at least the desired accuracy (potentially better)
                                      strongSelf.statusLabel.text = [NSString stringWithFormat:@"Location request successful! Current Location:\n%@", currentLocation];
                                      [strongSelf reverseGeocodeWithLocation:currentLocation];
                                  }
                                  else if (status == INTULocationStatusTimedOut) {
                                      // You may wish to inspect achievedAccuracy here to see if it is acceptable, if you plan to use currentLocation
                                      strongSelf.statusLabel.text = [NSString stringWithFormat:@"Location request timed out. Current Location:\n%@", currentLocation];
                                  }
                                  else {
                                      // An error occurred
                                      strongSelf.statusLabel.text = [strongSelf getErrorDescription:status];
                                  }
                              }];
}

- (void)reverseGeocodeWithLocation:(CLLocation *)rawLocation {
    SSLocation *processedLocation = [[SSLocation alloc] initWithCLLocation:rawLocation];
    
    __weak __typeof(self)weakSelf = self;
    __weak SSLocation *weakProcessedLocation = processedLocation;
    [processedLocation startReverseGeocodeWithCompletionHandler:^(NSError *error) {
        if (error) {
            weakSelf.statusLabel.text = error.localizedDescription;
        }
        else {
            weakSelf.location = weakProcessedLocation;
            weakSelf.statusLabel.text = weakProcessedLocation.description;
        }
    }];
}

- (IBAction)navigationAction:(id)sender {
    CLLocationCoordinate2D fromcoord = self.location.coordinate;
    CLLocationCoordinate2D tocoord = self.tocoord;

    NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString *displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *scheme = @"rongrong";
    
    NSMutableArray *navModels = [NSMutableArray array];
    // 高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        MapNavModel *model = [[MapNavModel alloc] init];
        model.type = MapNavTypeAmap;
        model.urlString = [NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2", [displayName URLEncodedString], scheme, tocoord.latitude,tocoord.longitude];
        [navModels addObject:model];
    }
    
    // 百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        MapNavModel *model = [[MapNavModel alloc] init];
        model.type = MapNavTypeBaidu;
        model.urlString = [NSString stringWithFormat:@"baidumap://map/direction?origin=%f,%f&destination=%f,%f&mode=driving&src=%@&coord_type=gcj02", fromcoord.latitude, fromcoord.longitude, tocoord.latitude, tocoord.longitude, bundleName];
        [navModels addObject:model];
    }
    
    // 腾讯地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"qqmap://"]]) {
        MapNavModel *model = [[MapNavModel alloc] init];
        model.type = MapNavTypeTencent;
        model.urlString = [NSString stringWithFormat:@"qqmap://map/routeplan?type=drive&fromcoord=%f,%f&tocoord=%f,%f", fromcoord.latitude, fromcoord.longitude, tocoord.latitude,tocoord.longitude];
        [navModels addObject:model];
    }
    
    // Google地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        MapNavModel *model = [[MapNavModel alloc] init];
        model.type = MapNavTypeGoogle;
        model.urlString = [NSString stringWithFormat:@"comgooglemaps://?saddr=%f,%f&daddr=%f,%f&directionsmode=driving", fromcoord.latitude, fromcoord.longitude, tocoord.latitude, tocoord.longitude];
        [navModels addObject:model];
    }
    
    // 系统地图
    MapNavModel *model = [[MapNavModel alloc] init];
    model.type = MapNavTypeApple;
    model.title = self.toTitle;
    [navModels addObject:model];
    
    self.navModels = [NSArray arrayWithArray:navModels];
    
    
    UIActionSheet *navActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    for (MapNavModel *model in self.navModels) {
        [navActionSheet addButtonWithTitle:model.typeName];
    }
    [navActionSheet addButtonWithTitle:@"取消"];
    navActionSheet.cancelButtonIndex = navModels.count;
    [navActionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"bttonIndex:%ld", buttonIndex);
    if (buttonIndex >= self.navModels.count) {
        return;
    }
    
    MapNavModel *model = self.navModels[buttonIndex];
    if (model.type == MapNavTypeApple) {
        MKPlacemark *fromPlacemark = [[MKPlacemark alloc] initWithCoordinate:self.location.coordinate addressDictionary:nil];
        MKPlacemark *toPlacemark = [[MKPlacemark alloc] initWithCoordinate:self.tocoord addressDictionary:nil];
        MKMapItem *fromMapItem = [[MKMapItem alloc] initWithPlacemark:fromPlacemark];
        fromMapItem.name = @"当前位置";
        MKMapItem *toMapItem = [[MKMapItem alloc] initWithPlacemark:toPlacemark];
        toMapItem.name = model.title;

        [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:fromMapItem, toMapItem, nil]
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:@(YES)}];
    }
    else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:model.urlString]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    MapViewController *vc = segue.destinationViewController;
    vc.fromcoord = self.location.coordinate;
    vc.tocoord = self.tocoord;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
