//
//  ViewController.m
//  EasyChangeLocation
//
//  Created by mac on 2017/1/25.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
@import MapKit;
@import CoreLocation;

@interface ViewController ()<CLLocationManagerDelegate, MKMapViewDelegate>
{
    CLLocationManager *_locationManager;
}
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;

@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeLocationService];
    
    [self initializeMapView];


    

}

- (void)initializeLocationService {
    // 初始化定位管理器
    _locationManager = [[CLLocationManager alloc] init];
    // 设置代理
    _locationManager.delegate = self;
    // 设置定位精确度到米
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    // 设置过滤器为无
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    
    // 开始定位
    // 取得定位权限，有两个方法，取决于你的定位使用情况
    // 一个是requestAlwaysAuthorization，一个是requestWhenInUseAuthorization
    [_locationManager requestAlwaysAuthorization];//这句话ios8以上版本使用。
    [_locationManager startUpdatingLocation];

}

- (void)initializeMapView {
    
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.mapView.showsCompass = YES; // 是否显示指南针
    self.mapView.showsScale = YES; // 是否显示比例尺
    self.mapView.showsTraffic = YES; // 是否显示交通
    self.mapView.showsBuildings = YES; // 是否显示建筑物
    self.mapView.delegate = self;
}
#pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    NSLog(@"----%@---", @"f");
    
}
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    // If the annotation is the user location, just return nil.（如果是显示用户位置的Annotation,则使用默认的蓝色圆点）
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        // Try to dequeue an existing pin view first.（这里跟UITableView的重用差不多）
        MKPinAnnotationView *customPinView = (MKPinAnnotationView*)[mapView
                                                                    dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        if (!customPinView){
            // If an existing pin view was not available, create one.
            customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                            reuseIdentifier:@"CustomPinAnnotationView"];
        }
        //iOS9中用pinTintColor代替了pinColor
        customPinView.pinColor = MKPinAnnotationColorPurple;
        customPinView.animatesDrop = YES;
        customPinView.canShowCallout = YES;

        return customPinView;
        
        

    }
    return nil;//返回nil代表使用默认样式
}
#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //将经度显示到label上
    self.longitudeLabel.text = [NSString stringWithFormat:@"%lf", newLocation.coordinate.longitude];
    //将纬度现实到label上
    self.latitudeLabel.text = [NSString stringWithFormat:@"%lf", newLocation.coordinate.latitude];
    
    // 获取当前所在的城市名
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //根据经纬度反向地理编译出地址信息
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *array, NSError *error){
        if (array.count > 0){
            CLPlacemark *placemark = [array objectAtIndex:0];
            //将获得的所有信息显示到label上
            self.locationLabel.text = [placemark.addressDictionary[@"FormattedAddressLines"] firstObject];
            //获取城市
            NSString *city = placemark.locality;
            if (!city) {
                //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
                city = placemark.administrativeArea;
            }
        } else if (error == nil && [array count] == 0) {
            
            NSLog(@"No results were returned.");
        } else if (error != nil) {
            
            NSLog(@"An error occurred = %@", error);
        }
    }];
    //系统会一直更新数据，直到选择停止更新，因为我们只需要获得一次经纬度即可，所以获取之后就停止更新
    [manager stopUpdatingLocation];
}

#pragma mark - action
- (IBAction)didLongPressMapView:(UILongPressGestureRecognizer *)gestureRecognizer {
    //这里touchPoint是点击的某点在地图控件中的位置
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    
    //这里touchMapCoordinate就是该点的经纬度了
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    NSLog(@"touching %lf,%lf",touchMapCoordinate.latitude,touchMapCoordinate.longitude);
    
    MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
    annotationPoint.coordinate = touchMapCoordinate;
    annotationPoint.title =
    [NSString stringWithFormat:@"%lf  %lf",touchMapCoordinate.latitude,touchMapCoordinate.longitude];
    
    for (id<MKAnnotation> obj in self.mapView.annotations) {
        if ([obj coordinate].longitude == [annotationPoint coordinate].longitude &&
            [obj coordinate].latitude == [annotationPoint coordinate].latitude) {
            return;
        }
    }
    // 长按时重复添加
    [self.mapView addAnnotation:annotationPoint];
}

@end
