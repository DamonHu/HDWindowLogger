//
//  ViewController.m
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import "ViewController.h"
#import "HDWindowLogger.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [HDWindowLogger show];
    
    HDNormalLog(@"收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        HDErrorLog(@"sdf这个是错误的收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方");
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        HDWarnLog(@"收到就好丰盛的金凤凰就水电费交mmm换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方");
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        HDWarnLog(@"nnnnnnnnnnnn");
    });
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 130, 200, 100)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"点击添加日志" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(p_click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)p_click {
    HDWarnLog(@"点击按钮");
    NSLog(@"点击了按钮");
    [HDWindowLogger printLog:@"点击按钮" withLogType:kHDLogTypeWarn];
    NSDictionary *dic = @{@"hhhhhhh":@"撒旦法是打发斯蒂芬是打发斯蒂芬"};
    [HDWindowLogger printLog:dic withLogType:kHDLogTypeNormal];
    NSArray *array = @[@"2323232323",@"6666678798778",@"00000000"];
    [HDWindowLogger printLog:array withLogType:kHDLogTypeNormal];
}
@end
