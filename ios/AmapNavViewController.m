//
//  AmapNavViewController.m
//  RNAmap
//
//  Created by ZhangKui on 2018/7/24.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AmapNavViewController.h"
#import "RNBridgeModule.h"

#import "AppDelegate.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface AmapNavViewController ()<MAMapViewDelegate,AMapNaviWalkManagerDelegate,AMapNaviWalkViewDelegate,AMapSearchDelegate>

@property (nonatomic, strong) AMapNaviPoint *startPoint;
@property (nonatomic, strong) AMapNaviPoint *endPoint;
@property (nonatomic, strong) MAPointAnnotation *startAnnotation;
@property (nonatomic, strong) MAPointAnnotation *endAnnotation;

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) CLLocationManager *startManager;
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) MAPolyline *polyline;

@property (nonatomic, strong) AMapNaviWalkManager *walkManager;

@end

@implementation AmapNavViewController

- (void)viewWillAppear:(BOOL)animated
{
  AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  [app.nav setNavigationBarHidden:NO animated:animated];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  [app.nav setNavigationBarHidden:YES animated:animated];
  [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = @"路线规划";
  self.view.backgroundColor = [UIColor whiteColor];
  
  ///初始化获取POI对象
  [self initMapSearch];
  ///初始化导航点
  [self initStartProperties];
  [self initEndProperties];
  ///初始化地图
  [self initMapView];
  ///初始化AMapNaviWalkManager
  [self initWalkManager];
  ///初始化其它视图
  [self initMoreMenu];
}

- (void)initMoreMenu
{
  UIButton *btn1 = [[UIButton alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height-40, self.view.bounds.size.width/3, 40)];
  [btn1 setTitle:@"百度导航" forState:UIControlStateNormal];
  [btn1 setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
  [btn1 setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
  [btn1 addTarget:self action:@selector(clickBtn1) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:btn1];
  
  UIButton *btn2 = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width/3, self.view.bounds.size.height-40, self.view.bounds.size.width/3, 40)];
  [btn2 setTitle:@"高德导航" forState:UIControlStateNormal];
  [btn2 setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
  [btn2 setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
  [btn2 addTarget:self action:@selector(clickBtn2) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:btn2];
  
  UIButton *btn3 = [[UIButton alloc]initWithFrame:CGRectMake(2*self.view.bounds.size.width/3, self.view.bounds.size.height-40, self.view.bounds.size.width/3, 40)];
  [btn3 setTitle:@"苹果导航" forState:UIControlStateNormal];
  [btn3 setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
  [btn3 setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
  [btn3 addTarget:self action:@selector(clickBtn3) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:btn3];
}

// 定位起点坐标
- (void)initStartProperties
{
  self.startManager = [[CLLocationManager alloc] init];
  // 设置定位精度，十米，百米，最好
  self.startManager.desiredAccuracy=kCLLocationAccuracyBest;
  //每隔多少米定位一次（这里的设置为任何的移动）
  self.startManager.distanceFilter = kCLDistanceFilterNone;
  self.startManager.delegate = self; //代理设置
  
  // 开始时时定位
  if ([CLLocationManager locationServicesEnabled])
  {
    // 开启位置更新需要与服务器进行轮询所以会比较耗电，在不需要时用stopUpdatingLocation方法关闭;
    [self.startManager startUpdatingLocation];
  }else
  {
     [self showMsg:@"请开启定位功能"];
  }
}

//开启定位后会先调用此方法，判断有没有权限
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined)
  {
    //判断ios8 权限
    
    if([self.startManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
      [self.startManager requestAlwaysAuthorization]; // 永久授权
      [self.startManager requestWhenInUseAuthorization]; //使用中授权
    }
  }
  else if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedWhenInUse)
  {
    [self.startManager startUpdatingLocation];
  }
}

//成功获取到经纬度
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
  // 获取经纬度
  NSLog(@"纬度1:%f",newLocation.coordinate.latitude);
  NSLog(@"经度1:%f",newLocation.coordinate.longitude);
  // 坐标转换
  CLLocationCoordinate2D amapcoord = AMapCoordinateConvert(CLLocationCoordinate2DMake(newLocation.coordinate.latitude,newLocation.coordinate.longitude), AMapCoordinateTypeGPS);
  NSLog(@"纬度2:%f",amapcoord.latitude);
  NSLog(@"经度2:%f",amapcoord.longitude);
  self.startPoint   = [AMapNaviPoint locationWithLatitude:amapcoord.latitude longitude:amapcoord.longitude];
  // 停止位置更新
  [manager stopUpdatingLocation];
}

// 定位失败错误信息
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
  NSLog(@"error");
}

// 检索终点坐标
- (void)initEndProperties
{
  AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
  request.keywords            = @"华中师范大学大学";
  request.city                = @"武汉";
  request.types               = @"高等院校";
  request.requireExtension    = YES;
  
  /*  搜索SDK 3.2.0 中新增加的功能，只搜索本城市的POI。*/
  request.cityLimit           = YES;
  request.requireSubPOIs      = YES;
  [self.search AMapPOIKeywordsSearch:request];
}

// 初始化 AMapSearchAPI
- (void)initMapSearch
{
  self.search = [[AMapSearchAPI alloc] init];
  self.search.delegate = self;
}

// 初始化 MAMapView
- (void)initMapView
{
  if (self.mapView == nil)
  {
    self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.mapView setDelegate:self];
    self.startAnnotation= [[MAPointAnnotation alloc] init];
    self.endAnnotation = [[MAPointAnnotation alloc] init];
    [self.mapView addAnnotation:self.startAnnotation];
    [self.mapView addAnnotation:self.endAnnotation];
    [self.view addSubview:self.mapView]; ///如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
  }
}

// 初始化 AMapNaviWalkManager
- (void)initWalkManager
{
  if (self.walkManager == nil)
  {
    self.walkManager = [[AMapNaviWalkManager alloc] init];
    [self.walkManager setDelegate:self];
  }
}

// 计算步行规划路线
- (void)walkingRouteSearch
{
  // 设置步行线路规划参数
  AMapWalkingRouteSearchRequest *navi = [[AMapWalkingRouteSearchRequest alloc] init];
  // 出发点
  navi.origin = [AMapGeoPoint locationWithLatitude:self.startPoint.latitude
                                         longitude:self.startPoint.longitude];
  // 目的地
  navi.destination = [AMapGeoPoint locationWithLatitude:self.endPoint.latitude
                                              longitude:self.endPoint.longitude];
  // 设置标记
  self.startAnnotation.coordinate = CLLocationCoordinate2DMake(self.startPoint.latitude, self.startPoint.longitude);
  [self.startAnnotation setTitle:@"起点"];
  self.endAnnotation.coordinate = CLLocationCoordinate2DMake(self.endPoint.latitude, self.endPoint.longitude);
  [self.endAnnotation setTitle:@"终点"];
  [self.search AMapWalkingRouteSearch:navi];
}

// 处理结果
// POI 搜索回调
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
  if (response.pois.count == 0)
  {
    return;
  }
  //解析response获取POI信息
  
  for (AMapPOI *p in response.pois) {
    NSLog(@"%@*%@*%@",p.description,p.name,p.address);
  }
  self.endPoint = [AMapNaviPoint locationWithLatitude:response.pois[0].location.latitude longitude:response.pois[0].location.longitude];
  // 计算步行规划路线
  [self walkingRouteSearch];
}

// 处理结果
// 路径规划搜索回调
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
{
  if (response.route == nil)
  {
    return;
  }
  if (!self.polyline) {
    //构造折线对象
    self.polyline = [[MAPolyline alloc]init];
  }
  //解析response获取路径信息
  if (response.count > 0){
    //直接取第一个方案
    AMapPath *path = response.route.paths[0];
    //移除旧折线对象
    [self.mapView removeOverlay:self.polyline];
    //构造折线对象
    self.polyline = [self polylinesForPath:path];
    //添加新的遮盖，然后会触发代理方法(- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay)进行绘制
    [self.mapView addOverlay:_polyline];
  }
}

//绘制遮盖时执行的代理方法
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
  /* 自定义定位精度对应的MACircleView. */
  //画路线
  if ([overlay isKindOfClass:[MAPolyline class]])
  {
    //初始化一个路线类型的view
    MAPolylineRenderer *polygonView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
    //设置线宽颜色等
    polygonView.lineWidth = 4.f;
    polygonView.strokeColor = [UIColor colorWithRed:0.015 green:0.658 blue:0.986 alpha:1.000];
    polygonView.fillColor = [UIColor colorWithRed:0.940 green:0.771 blue:0.143 alpha:0.800];
    polygonView.lineJoinType = kMALineJoinRound;//连接类型
    //返回view，就进行了添加
    return polygonView;
  }
  return nil;
}

//路线解析
- (MAPolyline *)polylinesForPath:(AMapPath *)path{
  if (path == nil || path.steps.count == 0){
    return nil;
  }
  NSMutableString *polylineMutableString = [@"" mutableCopy];
  for (AMapStep *step in path.steps) {
    [polylineMutableString appendFormat:@"%@;",step.polyline];
  }
  
  NSUInteger count = 0;
  CLLocationCoordinate2D *coordinates = [self coordinatesForString:polylineMutableString
                                                   coordinateCount:&count
                                                        parseToken:@";"];
  
  MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
  
  free(coordinates), coordinates = NULL;
  return polyline;
}

//解析经纬度
- (CLLocationCoordinate2D *)coordinatesForString:(NSString *)string
                                 coordinateCount:(NSUInteger *)coordinateCount
                                      parseToken:(NSString *)token{
  if (string == nil){
    return NULL;
  }
  
  if (token == nil){
    token = @",";
  }
  
  NSString *str = @"";
  if (![token isEqualToString:@","]){
    str = [string stringByReplacingOccurrencesOfString:token withString:@","];
  }else{
    str = [NSString stringWithString:string];
  }
  
  NSArray *components = [str componentsSeparatedByString:@","];
  NSUInteger count = [components count] / 2;
  if (coordinateCount != NULL){
    *coordinateCount = count;
  }
  CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D*)malloc(count * sizeof(CLLocationCoordinate2D));
  
  for (int i = 0; i < count; i++){
    coordinates[i].longitude = [[components objectAtIndex:2 * i]     doubleValue];
    coordinates[i].latitude  = [[components objectAtIndex:2 * i + 1] doubleValue];
  }
  return coordinates;
}

// 当检索失败时，会进入 didFailWithError 回调函数，通过该回调函数获取产生的失败的原因
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
  NSLog(@"Error: %@", error);
}

// 以下为导航
- (void)clickBtn1
{
  NSLog(@"++++++百度地图:%@",[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]?@"YES":@"NO");
  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]])
  {
    NSString *url = [[NSString stringWithFormat:@"baidumap://map/direction?origin=latlng:%@,%@|name:我的位置&destination=latlng:%@,%@|name:%@&mode=driving", @"30.512782",@"114.170477",@"30.625339",@"114.260847",@"汉口火车站"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    if ([[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]] == NO)
    {
      [self showMsg:@"导航失败！"];
    }
  } else {
    [self showMsg:@"没有安装百度地图！"];
  };
}

- (void)clickBtn2
{
  NSLog(@"++++++高德地图:%@",[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]?@"YES":@"NO");
  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]])
  {
    NSString *url = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&poiname=%@&lat=%@&lon=%@&dev=1&style=2", @"AMap",@"汉口火车站",@"30.625339",@"114.260847"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    if ([[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]] == NO)
    {
      [self showMsg:@"导航失败！"];
    }
  } else {
    [self showMsg:@"没有安装高德地图！"];
  };
}

- (void)clickBtn3
{
  //起点
  MKMapItem *currentLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc]                         initWithCoordinate:CLLocationCoordinate2DMake((30.512782),(114.170477)) addressDictionary:nil]];
  currentLocation.name =@"我的位置";
  //目的地的位置
  CLLocationCoordinate2D coords =CLLocationCoordinate2DMake((30.625339),(114.260847));
  MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:coords addressDictionary:nil]];
  toLocation.name = @"汉口火车站";
  
  NSArray *items = [NSArray arrayWithObjects:currentLocation, toLocation, nil];
  NSDictionary *options = @{ MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsMapTypeKey: [NSNumber                                 numberWithInteger:MKMapTypeStandard], MKLaunchOptionsShowsTrafficKey:@YES };
  
  //打开苹果自身地图应用，并呈现特定的item
  [MKMapItem openMapsWithItems:items launchOptions:options];
  
}

// 提示
- (void)showMsg:(NSString *)errorMsg {
  // 1.弹框提醒
  // 初始化对话框
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
  // 弹出对话框
  [self presentViewController:alert animated:true completion:nil];
}

@end
