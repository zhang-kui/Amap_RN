//
//  RNBridgeModule.m
//  RNAmap
//
//  Created by ZhangKui on 2018/7/24.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "RNBridgeModule.h"
#import "React/RCTBridge.h"

// 导入跳转的页面
#import "AmapNavViewController.h"
// 导入AppDelegate，获取UINavigationController
#import "AppDelegate.h"

@implementation RNBridgeModule

RCT_EXPORT_MODULE();

// RN跳转原生界面
RCT_EXPORT_METHOD(RNOpenNative: (NSString *)msg) {
  NSLog(@"++++++RN传入原生界面的数据为:%@",msg);
  //主要这里必须使用主线程发送,不然有可能失效
  dispatch_async(dispatch_get_main_queue(), ^{
    AmapNavViewController *v = [[AmapNavViewController alloc]init];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [app.nav pushViewController:v animated:YES];
  });
}

@end
