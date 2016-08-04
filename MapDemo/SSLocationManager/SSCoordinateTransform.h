//
//  SSCoordinateTransform.h
//  MapDemo
//
//  Created by zhucuirong on 16/8/3.
//  Copyright © 2016年 SINOFAKE SINEP. All rights reserved.
//

#ifndef SSCoordinateTransform_h
#define SSCoordinateTransform_h

void wgs2gcj(double wgsLat, double wgsLng, double *gcjLat, double *gcjLng);
void gcj2wgs(double gcjLat, double gcjLng, double *wgsLat, double *wgsLng);
void gcj2wgs_exact(double gcjLat, double gcjLng, double *wgsLat, double *wgsLng);
double distance(double latA, double lngA, double latB, double lngB);

#endif /* SSCoordinateTransform_h */
