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
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 130, 200, 100)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"点击添加日志" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(p_click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [HDWindowLogger defaultWindowLogger].mCompleteLogOut = true;
    [HDWindowLogger show];
    [HDWindowLogger defaultWindowLogger].mPrivacyPassword = @"12345678901234561234567890123456";
}

- (void)p_click {
    HDNormalLog(@"正常显示内容");
    HDWarnLog(@"警告内容");
    HDErrorLog(@"点击按钮");
    HDPrivacyLog(@"这是一个加密内容sssss");
    NSDictionary *dic = @{@"hhhhhhh":@"撒旦法是打发斯蒂芬是打发斯蒂芬",@"2222":@"更多内容"};
    HDNormalLog(dic);
    NSArray *array = @[@"2323232323",@"6666678798778",@"00000000"];
    HDWarnLog(array);
}
@end
