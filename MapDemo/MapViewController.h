//
//  MapViewController.h
//  MapDemo
//
//  Created by zhucuirong on 15/11/15.
//  Copyright © 2015年 SINOFAKE SINEP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapViewController : UIViewController
@property (nonatomic, assign) CLLocationCoordinate2D fromcoord;
@property (nonatomic, assign) CLLocationCoordinate2D tocoord;

@end
