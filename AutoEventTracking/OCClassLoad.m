//
//  OCClassLoad.m
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/9.
//

#import "OCClassLoad.h"
#import <AutoEventTracking/AutoEventTracking-Swift.h>

@implementation OCClassLoad

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController UIViewControllerSwiftLoad];
        [UIApplication UIApplicationSwiftLoad];
        [UITableView UITableViewSwiftLoad];
        [UICollectionView UICollectionViewSwiftLoad];
    });
}

@end
