//
//  ViewController.m
//  MapDemo
//
//  Created by zhucuirong on 15/11/14.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import "ViewController.h"
#import "NSString+URLEncoding.h"
#import "MapNavModel.h"
#import <MapKit/MapKit.h>
#import "MapViewController.h"
#import "SSLocationManager.h"
#import "SSCoordinateTransform.h"

@interface ViewController ()<UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, assign) CLLocationCoordinate2D fromcoord;
@property (nonatomic, assign) CLLocationCoordinate2D tocoord;
@property (nonatomic, copy) NSString *toTitle;

@property (nonatomic, strong) NSArray *navModels;

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
    self.tocoord = CLLocationCoordinate2DMake(39.9092509, 116.410599);

    self.toTitle = @"北京昆泰酒店";
}

- (IBAction)startLocationAction:(id)sender {
    SSLocationManager *locationManager = [SSLocationManager sharedInstance];
    locationManager.baiduAppKey = @"1OevpbfPmU5uXuNMCj8Q8CpO";
    locationManager.baiduMcode = @"com.sskh.huaErSlimmingRing";
    
    [locationManager requestLocationWithDesiredAccuracy:INTULocationAccuracyBlock locationBlock:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status, NSString *statusDescription) {
        self.statusLabel.text = statusDescription;
        if (status == INTULocationStatusSuccess) {
            self.location = currentLocation;
        }
    } reverseGeocodeBlock:^(SSAddress *address, NSError *error) {
        if (error) {
            self.statusLabel.text = error.localizedDescription;
        } else {
            self.statusLabel.text = address.description;
        }
    }];
}

- (IBAction)navigationAction:(id)sender {
    self.fromcoord = self.location.coordinate;

    SSLocationManager *locationManager = [SSLocationManager sharedInstance];
    if (locationManager.inMainland) {
        double gcjLat;
        double gcjLng;
        wgs2gcj(self.location.coordinate.latitude, self.location.coordinate.longitude, &gcjLat, &gcjLng);
        self.fromcoord = CLLocationCoordinate2DMake(gcjLat, gcjLng);
    }
    
    CLLocationCoordinate2D fromcoord = self.fromcoord;
    CLLocationCoordinate2D tocoord = self.tocoord;

    NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString *displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *scheme = @"rongrong";
    
    NSMutableArray *navModels = [NSMutableArray array];
    // 高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        MapNavModel *model = [[MapNavModel alloc] init];
        model.type = MapNavTypeAmap;
        //参数说明：http://lbs.amap.com/api/uri-api/ios-uri-explain/
        model.urlString = [NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2", [displayName URLEncodedString], scheme, tocoord.latitude,tocoord.longitude];
        [navModels addObject:model];
    }
    
    // 百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        MapNavModel *model = [[MapNavModel alloc] init];
        model.type = MapNavTypeBaidu;
        //参数说明：http://developer.baidu.com/map/uri-intro.htm
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
        MKPlacemark *fromPlacemark = [[MKPlacemark alloc] initWithCoordinate:self.fromcoord addressDictionary:nil];
        MKPlacemark *toPlacemark = [[MKPlacemark alloc] initWithCoordinate:self.tocoord addressDictionary:nil];
        MKMapItem *fromMapItem = [[MKMapItem alloc] initWithPlacemark:fromPlacemark];
        fromMapItem.name = @"当前位置";
        MKMapItem *toMapItem = [[MKMapItem alloc] initWithPlacemark:toPlacemark];
        toMapItem.name = model.title;

        [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:fromMapItem, toMapItem, nil]
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:@(YES)}];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:model.urlString]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    MapViewController *vc = segue.destinationViewController;
    SSAnnotation *annotation = [[SSAnnotation alloc] init];
    annotation.coordinate = self.tocoord;
    annotation.title = @"title";
    annotation.subtitle = @"subtitle";
    vc.annotation = annotation;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
