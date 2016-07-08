//
//  MapViewController.m
//  MapDemo
//
//  Created by zhucuirong on 15/11/15.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController ()<MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;


@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.userLocation.title = @"当前位置";
    
    [self.mapView addAnnotation:self.annotation];
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.annotation.coordinate, 5000, 5000)];
}

/**
 经纬度互换度(DDD)：E 108.90593度    N 34.21630度
 
 如何将度(DDD):： 108.90593度换算成度分秒(DMS)东经E 108度54分22.2秒?转换方法是将108.90593整数位不变取108(度),用0.90593*60=54.3558,取整数位54(分),0.3558*60=21.348再取整数位21(秒),故转化为108度54分21秒.
 
 同样将度分秒(DMS):东经E 108度54分22.2秒 换算成度(DDD)的方法如下:108度54分22.2秒=108+(54/60)+(22.2/3600)=108.90616度
 
 因为计算时小数位保留的原因，导致正反计算存在一定误差，但误差影响不是很大。1秒的误差就是几米的样子。GPS车友可以用上述方法换算成自己需要的单位坐标。
 */

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.mapView selectAnnotation:self.annotation animated:YES];
}

#pragma mark - MKMapViewDelegate
- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    static NSString *annotationID = @"annotationID";
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:annotationID];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self.annotation reuseIdentifier:annotationID];
        annotationView.image = [UIImage imageNamed:@"hotelCurrentLocation"];
        annotationView.canShowCallout = YES;
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.rightCalloutAccessoryView = btn;
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    NSLog(@"control:%@", control);
    [self navigateClick:nil];
}

/**
 在添加大头针图像出现之前调用，可以设置大头针的掉落效果
 参数 views 大头针掉落后的图像，将大头针的y值设置为0（顶部），再动画回到原来的位置可实现
 注意：不要将系统定位的大头针设置了动画效果
 */
#pragma mark - 实现大头针掉落动画效果
//代理方法在添加大头针图像出现之前调用，参数views 为放置的大头针
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views{
    for (MKAnnotationView *annoView in views) {
        // 不要将系统定位的大头针设置了动画效果
        if ([annoView.annotation isKindOfClass:[MKUserLocation class]]) {
            return;
        }
        // 记录要放置的大头针坐标的位置
        CGRect startFrame = annoView.frame;
        // 位置的 Y 改为0，用来掉落
        annoView.frame = CGRectMake(startFrame.origin.x, 0, startFrame.size.width, startFrame.size.height);
        // 执行动画掉落
        [UIView animateWithDuration:0.25 animations:^{
            annoView.frame = startFrame;
        }];
    }
}

#pragma mark - 地图画线，在mapView中，iOS8以后无法在模拟器运行
/**
 步骤：（就是各种转换，步骤多的看着就恶心，可以直接看下面代码）
 1、创建地理编码对象，调用正地理编码方法，获取 CLPlacemark 地标对象
 2、构造方法用上面参数创建一个 MKPlacemark 对象
 3、构造方法用上面参数创建两个个 MKMapItem 对象，作为起点和终点位置
 4、创建方向请求对象（ MKDirectionsRequest ），分别设置起点和终点（ source、 destination）
 5、创建方向对象（ MKDirections ），构造方法利用上面的请求对象
 6、用方向对象调用计算两点之间的路线方法，回调获取 MKDirectionsResponse 类型响应
 7、从响应对象中获取一组路线对象（ MKRoute）路线对象，有些属性天朝用不了，如暴风雪路线
 8、遍历该组路线对象，取出每个折线（ polyline属性 MKPolyline类型）分别渲染到mapView上（通过mapView的 addOverlay:方法）
 9、在mapView代理方法中创建地图渲染物
 （1）创建折线渲染物对象（ MKPolylineRenderer ），构造方法利用代理的 overlay 参数
 （2）设置线条颜色（必须设置，否则不显示 fillColor 或 strokeColor ）
 （3）返回渲染对象
 */
#pragma mark 画线按钮点击
- (IBAction)navigateClick:(id)sender {
//    //1. 创建CLGeocoder对象
//    CLGeocoder *geocoder = [CLGeocoder new];
//    //2. 调用地理编码方法
//    [geocoder geocodeAddressString:@"天津" completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
//        //3 防错处理
//        if (placemarks.count == 0 || error) {
//            return;
//        }
//        //4. 获取地表对象 暂取最后一个
//        CLPlacemark *pm = placemarks.lastObject;
//        //5. 创建MKPlacemark对象
//        MKPlacemark *mkpm = [[MKPlacemark alloc] initWithPlacemark:pm];
    
        //6.1 创建一个终点MKMapItem
        MKPlacemark *mkpm = [[MKPlacemark alloc] initWithCoordinate:self.annotation.coordinate addressDictionary:nil];
        MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:mkpm];

        //6.2 创建一个起点MKMapItem（当前位置）
        MKMapItem *souceItem = [MKMapItem mapItemForCurrentLocation];
        
        //7. 创建一个方向请求对象，分别设置起点和终点
        MKDirectionsRequest *request = [MKDirectionsRequest new];
        //7.1 设置终点
        request.destination = destinationItem;
        //7.2 设置起点
        request.source = souceItem;
        
        //8. 创建方向对象，利用请求对象
        MKDirections *direction = [[MKDirections alloc] initWithRequest:request];
        //9. 调用请求对象的 计算路径方法
        [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
            //10.1 防错处理
            if (response.routes.count == 0 || error) {
                NSLog(@"没有找到对应的路线");
                return ;
            }
            //10.2 从返回的response中获取一组 MKRoute 路线对象
            for (MKRoute *route in response.routes) {
                //11. 从路线对象中获取折线对象
                MKPolyline *polyline = route.polyline;
                //12. 将折线对象通过渲染方式添加到地图上，注意在渲染的代理方法中为折线设置颜色
                [self.mapView addOverlay:polyline];
            }
            
            [self adjustMapToCenter];
        }];
//    }];
}

- (void)adjustMapToCenter {
    MKUserLocation *userLocation = self.mapView.userLocation;
    CLLocationDegrees minLat = MIN(userLocation.coordinate.latitude, self.annotation.coordinate.latitude);
    CLLocationDegrees maxLat = MAX(userLocation.coordinate.latitude, self.annotation.coordinate.latitude);
    CLLocationDegrees minLon = MIN(userLocation.coordinate.longitude, self.annotation.coordinate.longitude);
    CLLocationDegrees maxLon = MAX(userLocation.coordinate.longitude, self.annotation.coordinate.longitude);
    //计算中心点
    CLLocationCoordinate2D centCoor;
    centCoor.latitude = (CLLocationDegrees)((maxLat+minLat) * 0.5f);
    centCoor.longitude = (CLLocationDegrees)((maxLon+minLon) * 0.5f);
    MKCoordinateSpan span;
    //计算地理位置的跨度
    span.latitudeDelta = maxLat - minLat + 0.012;
    span.longitudeDelta = maxLon - minLon + 0.002;
    //得出数据的坐标区域
    MKCoordinateRegion region = MKCoordinateRegionMake(centCoor, span);
    [self.mapView setRegion:region animated:YES];
}

#pragma mark - mapView的代理方法，当给地图添加了遮盖物的时候就会用此方法，设置一个渲染物对象添加到地图上
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    //1. 创建一个折线渲染物对象（MKOverlayRenderer的子类）
    MKPolylineRenderer *polyline = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    //2. 设置线条颜色，必须设置,否则看不见
    //polyline.fillColor = [UIColor redColor];
    polyline.strokeColor = [UIColor blueColor];
    //3. 设置线条宽度
    polyline.lineWidth = 5;
    return polyline;
}
@end
