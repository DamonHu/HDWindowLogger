//
//  HDWindowLogger.m
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import "HDWindowLogger.h"
#import "HDLoggerTableViewCell.h"
#import <CommonCrypto/CommonCryptor.h>
#import "Masonry.h"


#pragma mark -
#pragma mark - HDWindowLogger
@interface HDWindowLogger () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate>
@property (strong, nonatomic, readwrite) NSMutableArray *mLogDataArray;  //log信息内容
@property (strong, nonatomic) NSMutableArray *mFilterIndexArray;       //搜索的索引的index
@property (assign, nonatomic) NSInteger mMaxLogCount;      //最大数

@property (strong, nonatomic) UIView *mBGView;
@property (strong, nonatomic) UITableView *mTableView;
@property (strong, nonatomic) UIButton *mCleanButton;
@property (strong, nonatomic) UITextField *mPasswordTextField;
@property (copy, nonatomic) NSString *mTextPassword;         //输入的解密密码
@property (strong, nonatomic) UIButton *mPasswordButton;
@property (strong, nonatomic) UIButton *mScaleButton;
@property (strong, nonatomic) UIButton *mHideButton;
@property (strong, nonatomic) UIButton *mShareButton;
@property (strong, nonatomic) UIWindow *mFloatWindow;
@property (strong, nonatomic) UILabel *mSwitchLabel;
@property (strong, nonatomic) UISwitch *mAutoScrollSwitch; //输出自动滚动
@property (strong, nonatomic) UISearchBar *mSearchBar;
@property (strong, nonatomic) UIButton *mPreviousButton;      //上一条
@property (strong, nonatomic) UIButton *mNextButton;          //下一条
@property (strong, nonatomic) UILabel *mSearchNumLabel;       //搜索条数
@property (strong, nonatomic) UILabel *mTipLabel;       //显示
@property (assign, nonatomic) NSInteger mCurrentSearchIndex;  //当前搜索到的索引
@end

@implementation HDWindowLogger

#pragma mark -
#pragma mark - init Method
+ (HDWindowLogger *)defaultWindowLogger {
    static HDWindowLogger *defaultLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!defaultLogger) {
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
                    if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                        defaultLogger = [[HDWindowLogger alloc] initWithWindowScene:windowScene];
                    }
                }
            }
            if (!defaultLogger) {
                defaultLogger = [[HDWindowLogger alloc] init];
            }
        }
    });
    return defaultLogger;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.rootViewController = [UIViewController new]; // suppress warning
        self.windowLevel = UIWindowLevelStatusBar;
        [self setBackgroundColor:[UIColor clearColor]];
        self.mMaxLogCount = 0;
        self.mCompleteLogOut = true;
        self.mDebugAreaLogOut = true;
        self.mPrivacyPassword = @"";
        self.mTextPassword = @"";
        self.userInteractionEnabled = YES;
        [self p_createUI];
        [self p_bindClick];
    }
    return self;
}

#ifdef __IPHONE_13_0
- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    self = [super initWithWindowScene:windowScene];
    if (self) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.rootViewController = [UIViewController new]; // suppress warning
            self.windowLevel = UIWindowLevelStatusBar;
            [self setBackgroundColor:[UIColor clearColor]];
            self.mMaxLogCount = 0;
            self.mCompleteLogOut = true;
            self.mDebugAreaLogOut = true;
            self.mPrivacyPassword = @"";
            self.mTextPassword = @"";
            self.userInteractionEnabled = YES;
            [self p_createUI];
            [self p_bindClick];
        });
    }
    return self;
}
#endif

- (BOOL)mPasswordCorrect {
    return [self.mTextPassword isEqualToString:self.mPrivacyPassword];
}

#pragma mark -
#pragma mark - Public Method

/**
 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
 
 @param log 日志内容
 @param logType 日志类型
 */
+ (void)printLog:(id)log withLogType:(HDLogType)logType {
    [self printLog:log withLogType:logType file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ functionName:[NSString stringWithFormat:@"%s",__FUNCTION__]];
}

///  根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
/// @param log 日志内容
/// @param logType 日志类型
/// @param fileName 调用输出的文件
/// @param line 调用输出的行数
/// @param funcationName 调用输出的函数名
+ (void)printLog:(id)log withLogType:(HDLogType)logType file:(NSString *)fileName line:(NSInteger)line functionName:(NSString *)funcationName {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self defaultWindowLogger].mLogDataArray.count == 0) {
            //如果是第一条，就插入一条默认帮助提示
            HDWindowLoggerItem *item = [[HDWindowLoggerItem alloc] init];
            item.mLogItemType = kHDLogTypeWarn;
            item.mCreateDate = [NSDate date];
            item.mLogDebugContent = @"";
            item.mLogContent = NSLocalizedString(@"HDWindowLogger: 点击对应日志可快速复制", nil);
            [[self defaultWindowLogger].mLogDataArray addObject:item];
        }
        HDWindowLoggerItem *item = [[HDWindowLoggerItem alloc] init];
        item.mLogItemType = logType;
        item.mCreateDate = [NSDate date];
        item.mLogDebugContent = [NSString stringWithFormat:@"[File:\(%@)]:[Line:\(%ld):[Function:\(%@)]]-Log:",fileName,(long)line,funcationName];
        item.mLogContent = log;
        if ([self defaultWindowLogger].mDebugAreaLogOut) {
            NSLog(@"%@",[item getFullContentString]);
        }
        
        
        
        [[self defaultWindowLogger].mLogDataArray addObject:item];
        if ([self defaultWindowLogger].mMaxLogCount > 0 && [self defaultWindowLogger].mLogDataArray.count > [self defaultWindowLogger].mMaxLogCount) {
            [[self defaultWindowLogger].mLogDataArray removeObjectAtIndex:0];
        }
        
        [[self defaultWindowLogger] p_reloadFilter];
        //滚动到底部
        if ([self defaultWindowLogger].mLogDataArray.count > 0 && [self defaultWindowLogger].mAutoScrollSwitch.isOn) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self defaultWindowLogger].mTableView  scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self defaultWindowLogger].mLogDataArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            });
        }
    });
}

/**
 删除log日志
 */
+ (void)cleanLog {
    [[self defaultWindowLogger].mLogDataArray removeAllObjects];
    [[self defaultWindowLogger].mFilterIndexArray removeAllObjects];
    [[self defaultWindowLogger].mTableView reloadData];
}

/**
 显示log窗口
 */
+ (void)show {
    [self defaultWindowLogger].hidden = NO;
    [self defaultWindowLogger].userInteractionEnabled = YES;
    [self defaultWindowLogger].mBGView.hidden = NO;
    [self defaultWindowLogger].mFloatWindow.hidden = YES;
}


/**
 隐藏整个log窗口
 */
+ (void)hide {
    [self defaultWindowLogger].hidden = YES;
    [self defaultWindowLogger].mBGView.hidden = YES;
    [self defaultWindowLogger].mFloatWindow.hidden = YES;
}


/**
 只隐藏log的输出窗口，保留悬浮图标
 */
+ (void)hideLogWindow {
    [self defaultWindowLogger].userInteractionEnabled = NO;
    [self defaultWindowLogger].mBGView.hidden = YES;
    [self defaultWindowLogger].mFloatWindow.hidden = NO;
}

/**
 为了节省内存，可以设置记录的最大的log数，超出限制删除最老的数据，默认不限制
 
 @param logCount 0为不限制
 */
+ (void)setMaxLogCount:(NSInteger)logCount {
    [self defaultWindowLogger].mMaxLogCount = logCount;
}

#pragma mark -
#pragma mark - Private Method
- (void)p_createUI {
    [self setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 350)];
    ///添加主视图
    [self.rootViewController.view addSubview:self.mBGView];
    [self.mBGView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.rootViewController.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.equalTo(self.rootViewController.mas_topLayoutGuideBottom);
        }
        make.left.right.bottom.equalTo(self.rootViewController.view);
    }];
    
    //按钮
    [self.mBGView addSubview:self.mScaleButton];
    [self.mScaleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.mBGView);
        make.width.mas_equalTo([UIScreen mainScreen].bounds.size.width/4.0);
        make.height.mas_equalTo(40);
    }];
    
    [self.mBGView addSubview:self.mHideButton];
    [self.mHideButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mScaleButton);
        make.left.equalTo(self.mScaleButton.mas_right);
        make.width.mas_equalTo([UIScreen mainScreen].bounds.size.width/4.0);
        make.height.mas_equalTo(40);
    }];
    
    [self.mBGView addSubview:self.mShareButton];
    [self.mShareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mHideButton.mas_right);
        make.width.height.top.equalTo(self.mHideButton);
    }];
    [self.mBGView addSubview:self.mCleanButton];
    [self.mCleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mShareButton.mas_right);
        make.width.height.top.equalTo(self.mHideButton);
    }];
    
    //解密
    [self.mBGView addSubview:self.mPasswordTextField];
    [self.mPasswordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mBGView);
        make.top.equalTo(self.mHideButton.mas_bottom);
        make.width.mas_equalTo([UIScreen mainScreen].bounds.size.width/3.0 + 50);
        make.height.mas_equalTo(40);
    }];
    [self.mBGView addSubview:self.mPasswordButton];
    [self.mPasswordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mPasswordTextField.mas_right);
        make.top.equalTo(self.mPasswordTextField);
        make.width.mas_equalTo([UIScreen mainScreen].bounds.size.width/3.0 - 50);
        make.height.mas_equalTo(40);
    }];
    
    
    [self.mBGView addSubview:self.mAutoScrollSwitch];
    [self.mAutoScrollSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.mBGView).offset(-10);
        make.centerY.equalTo(self.mPasswordButton);
    }];
    
    //开关视图
    [self.mBGView addSubview:self.mSwitchLabel];
    [self.mSwitchLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mPasswordButton.mas_right);
        make.right.equalTo(self.mAutoScrollSwitch.mas_left);
        make.centerY.equalTo(self.mPasswordButton);
    }];
    
    //滚动日志窗
    [self.mBGView addSubview:self.mTableView];
    [self.mTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.mBGView);
        make.top.equalTo(self.mPasswordTextField.mas_bottom);
        make.bottom.equalTo(self.mBGView).offset(-60);
    }];
    
    //搜索
    [self.mBGView addSubview:self.mSearchBar];
    [self.mSearchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mTableView.mas_bottom);
        make.left.equalTo(self.mBGView);
        make.bottom.equalTo(self.mBGView).offset(-20);
        make.width.mas_equalTo([UIScreen mainScreen].bounds.size.width - 180);
    }];
    
    //
    [self.mBGView addSubview:self.mPreviousButton];
    [self.mPreviousButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.mSearchBar);
        make.left.equalTo(self.mSearchBar.mas_right);
        make.width.mas_equalTo(60);
    }];
    
    [self.mBGView addSubview:self.mNextButton];
    [self.mNextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.mSearchBar);
        make.left.equalTo(self.mPreviousButton.mas_right);
        make.width.mas_equalTo(60);
    }];
    
    [self.mBGView addSubview:self.mSearchNumLabel];
    [self.mSearchNumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.mSearchBar);
        make.left.equalTo(self.mNextButton.mas_right);
        make.right.equalTo(self.mBGView);
    }];
    
    [self.mBGView addSubview:self.mTipLabel];
    [self.mTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.mBGView);
        make.top.equalTo(self.mSearchBar.mas_bottom);
        make.bottom.equalTo(self.mBGView);
    }];
}

- (void)p_bindClick {
    [self.mScaleButton addTarget:self action:@selector(p_scale) forControlEvents:UIControlEventTouchUpInside];
    [self.mHideButton addTarget:self action:@selector(p_hideLogWindow) forControlEvents:UIControlEventTouchUpInside];
    [self.mCleanButton addTarget:self action:@selector(p_cleanLog) forControlEvents:UIControlEventTouchUpInside];
    [self.mShareButton addTarget:self action:@selector(p_share) forControlEvents:UIControlEventTouchUpInside];
    [self.mPasswordButton addTarget:self action:@selector(p_decrypt) forControlEvents:UIControlEventTouchUpInside];
    [self.mPreviousButton addTarget:self action:@selector(p_previous) forControlEvents:UIControlEventTouchUpInside];
    [self.mNextButton addTarget:self action:@selector(p_next) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)p_scale {
    self.mScaleButton.selected = !self.mScaleButton.isSelected;
    if (self.mScaleButton.isSelected) {
        [self setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 20)];
    } else {
        [self setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 350)];
    }
}

- (void)p_hideLogWindow {
    [HDWindowLogger hideLogWindow];
}

- (void)p_cleanLog {
    [HDWindowLogger cleanLog];
}

- (void)p_show {
    [HDWindowLogger show];
}

- (void)p_share {
    //文件路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"HDWindowLogger.txt"];// 注意不是NSData!
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    
    NSString *content = @"";
    for (HDWindowLoggerItem *item in self.mLogDataArray) {
        content = [content stringByAppendingString:[item getFullContentString]];
    }

    [content writeToFile:logFilePath atomically:true encoding:NSUTF8StringEncoding error:nil];
    
    //分享
    NSURL *url = [NSURL fileURLWithPath:logFilePath];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:url, nil] applicationActivities:nil];
    if ([[UIDevice currentDevice].model isEqualToString:@"iPad"]) {
        activityVC.modalPresentationStyle = UIModalPresentationPopover;
        activityVC.popoverPresentationController.sourceView = self.mShareButton;
        activityVC.popoverPresentationController.sourceRect = self.mShareButton.frame;
    }
    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
    };
    [self p_hideLogWindow];
    [[self p_getCurrentVC] presentViewController:activityVC animated:YES completion:nil];
}

- (void)p_touchMove:(UIPanGestureRecognizer*)p {
    CGPoint panPoint = [p locationInView:[[UIApplication sharedApplication] keyWindow]];
    if (p.state == UIGestureRecognizerStateChanged) {
        self.mFloatWindow.center = CGPointMake(panPoint.x, panPoint.y);
    }
}

///更新筛选查找的数据
- (void)p_reloadFilter {
    //恢复默认显示
    [self.mFilterIndexArray removeAllObjects];
    self.mPreviousButton.enabled = false;
    self.mNextButton.enabled = false;
    self.mSearchNumLabel.text = NSLocalizedString(@"0条结果", nil);
    NSString *searchText = self.mSearchBar.text;
    if (searchText.length > 0) {
        NSArray *copyArray = [NSArray arrayWithArray:self.mLogDataArray];
        [copyArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HDWindowLoggerItem * item, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[item getFullContentString] localizedCaseInsensitiveContainsString:searchText]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                    [self.mFilterIndexArray addObject:indexPath];
                    self.mPreviousButton.enabled = true;
                    self.mNextButton.enabled = true;
                    self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
                    self.mSearchNumLabel.text = [NSString stringWithFormat:@"%ld/%lu",(long)self.mCurrentSearchIndex + 1, (unsigned long)self.mFilterIndexArray.count];
                });
            }
            if (idx == copyArray.count - 1) {
                *stop = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.mTableView reloadData];
                });
            }
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mTableView reloadData];
        });
    }
}

//上一条
- (void)p_previous {
    if (self.mFilterIndexArray.count > 0) {
        self.mCurrentSearchIndex = self.mCurrentSearchIndex - 1;
        if (self.mCurrentSearchIndex < 0) {
            self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
        }
        self.mSearchNumLabel.text = [NSString stringWithFormat:@"%ld/%lu",(long)self.mCurrentSearchIndex + 1, (unsigned long)self.mFilterIndexArray.count];
        NSIndexPath *indexPath = [self.mFilterIndexArray objectAtIndex:self.mCurrentSearchIndex];
        [self.mTableView  scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

//下一条
- (void)p_next {
    if (self.mFilterIndexArray.count > 0) {
        self.mCurrentSearchIndex = self.mCurrentSearchIndex + 1;
        if (self.mCurrentSearchIndex == self.mFilterIndexArray.count) {
            self.mCurrentSearchIndex = 0;
        }
        self.mSearchNumLabel.text = [NSString stringWithFormat:@"%ld/%lu",(long)self.mCurrentSearchIndex + 1, (unsigned long)self.mFilterIndexArray.count];
        NSIndexPath *indexPath = [self.mFilterIndexArray objectAtIndex:self.mCurrentSearchIndex];
        [self.mTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

//点击解密
- (void)p_decrypt {
    [self.mPasswordTextField resignFirstResponder];
    [self.mSearchBar resignFirstResponder];
    [self.mTableView reloadData];
}

- (UIViewController *)p_getCurrentVC {
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    UIViewController *result = nil;
    if ([window subviews].count>0) {
        UIView *frontView = [[window subviews] objectAtIndex:0];
        id nextResponder = [frontView nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
            result = nextResponder;
        else
            result = window.rootViewController;
    }
    else{
        result = window.rootViewController;
    }
    if ([result isKindOfClass:[UITabBarController class]]) {
        result = [((UITabBarController*)result) selectedViewController];
    }
    if ([result isKindOfClass:[UINavigationController class]]) {
        result = [((UINavigationController*)result) visibleViewController];
    }
    return result;
}

#pragma mark -
#pragma mark - Lazyload
- (NSMutableArray *)mLogDataArray {
    if (!_mLogDataArray) {
        _mLogDataArray = [NSMutableArray array];
    }
    return _mLogDataArray;
}

- (NSMutableArray *)mFilterIndexArray {
    if (!_mFilterIndexArray) {
        _mFilterIndexArray = [NSMutableArray array];
    }
    return _mFilterIndexArray;
}

- (UIView *)mBGView {
    if (!_mBGView) {
        _mBGView = [[UIView alloc] init];
        [_mBGView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
    }
    return _mBGView;
}

- (UITableView *)mTableView {
    if (!_mTableView) {
        _mTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _mTableView.scrollsToTop = YES;
        _mTableView.dataSource = self;
        _mTableView.delegate = self;
        _mTableView.showsHorizontalScrollIndicator = NO;
        _mTableView.showsVerticalScrollIndicator = YES;
        _mTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive| UIScrollViewKeyboardDismissModeOnDrag;
        _mTableView.backgroundColor = [UIColor clearColor];
        _mTableView.separatorColor = [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:240.0/255.0 alpha:1.0];
        _mTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _mTableView.separatorInset = UIEdgeInsetsMake(0, 5, 0, 5);
        _mTableView.estimatedRowHeight = 10;
        _mTableView.rowHeight = UITableViewAutomaticDimension;
    }
    return _mTableView;
}

- (UIButton *)mScaleButton {
    if (!_mScaleButton) {
        _mScaleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mScaleButton setBackgroundColor:[UIColor colorWithRed:168.0/255.0 green:223.0/255.0 blue:101.0/255.0 alpha:1.0]];
        [_mScaleButton setTitle:NSLocalizedString(@"伸缩", nil) forState:UIControlStateNormal];
    }
    return _mScaleButton;
}

- (UIButton *)mCleanButton {
    if (!_mCleanButton) {
        _mCleanButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mCleanButton setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:118.0/255.0 blue:118.0/255.0 alpha:1.0]];
        [_mCleanButton setTitle:NSLocalizedString(@"清除Log", nil) forState:UIControlStateNormal];
    }
    return _mCleanButton;
}

- (UIButton *)mHideButton {
    if (!_mHideButton) {
        _mHideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mHideButton setBackgroundColor:[UIColor colorWithRed:93.0/255.0 green:174.0/255.0 blue:139.0/255.0 alpha:1.0]];
        [_mHideButton setTitle:NSLocalizedString(@"隐藏", nil) forState:UIControlStateNormal];
    }
    return _mHideButton;
}

- (UIButton *)mShareButton {
    if (!_mShareButton) {
        _mShareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mShareButton setBackgroundColor:[UIColor colorWithRed:246.0/255.0 green:244.0/255.0 blue:157.0/255.0 alpha:1.0]];
        [_mShareButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:118.0/255.0 blue:118.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_mShareButton setTitle:NSLocalizedString(@"分享", nil) forState:UIControlStateNormal];
    }
    return _mShareButton;
}

- (UITextField *)mPasswordTextField {
    if (!_mPasswordTextField) {
        _mPasswordTextField = [[UITextField alloc] init];
        _mPasswordTextField.delegate = self;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"输入密码查看加密数据", comment: @"") attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:14],NSFontAttributeName,[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.7],NSForegroundColorAttributeName, nil]];
        _mPasswordTextField.attributedPlaceholder = attributedString;
        _mPasswordTextField.textColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.7];
        _mPasswordTextField.layer.masksToBounds = true;
        _mPasswordTextField.layer.borderColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor;
        _mPasswordTextField.layer.borderWidth = 1.0;
    }
    return _mPasswordTextField;
}

- (UIButton *)mPasswordButton {
    if (!_mPasswordButton) {
        _mPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _mPasswordButton.backgroundColor = [UIColor colorWithRed:27.0/255.0 green:108.0/255.0 blue:168.0/255.0 alpha:1.0];
        [_mPasswordButton setTitle:NSLocalizedString(@"解密", comment: @"") forState:UIControlStateNormal];
        [_mPasswordButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        _mPasswordButton.layer.masksToBounds = true;
        _mPasswordButton.layer.borderColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor;
        _mPasswordButton.layer.borderWidth = 1.0;
    }
    return _mPasswordButton;
}

- (UIWindow *)mFloatWindow {
    if (!_mFloatWindow) {
        _mFloatWindow = [[UIWindow alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 70, 50, 60, 60)];
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    _mFloatWindow = [[UIWindow alloc] initWithWindowScene:windowScene];
                    _mFloatWindow.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 70, 50, 60, 60);
                }
            }
        }
        _mFloatWindow.rootViewController = [UIViewController new]; // suppress warning
        _mFloatWindow.windowLevel = UIWindowLevelAlert;
        [_mFloatWindow setBackgroundColor:[UIColor clearColor]];
        _mFloatWindow.userInteractionEnabled = YES;
        
        UIButton *floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [floatButton setBackgroundColor:[UIColor colorWithRed:93.0/255.0 green:174.0/255.0 blue:139.0/255.0 alpha:1.0]];
        [floatButton setTitle:@"H" forState:UIControlStateNormal];
        [floatButton.titleLabel setFont:[UIFont systemFontOfSize:20]];
        floatButton.layer.masksToBounds = YES;
        floatButton.layer.cornerRadius = 30.0f;
        [floatButton addTarget:self action:@selector(p_show) forControlEvents:UIControlEventTouchUpInside];
        [_mFloatWindow.rootViewController.view addSubview:floatButton];
        [floatButton setFrame:CGRectMake(0, 0, 60, 60)];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(p_touchMove:)];
        [floatButton addGestureRecognizer:pan];
    }
    return _mFloatWindow;
}


- (UISwitch *)mAutoScrollSwitch {
    if (!_mAutoScrollSwitch) {
        _mAutoScrollSwitch = [[UISwitch alloc] init];
        _mAutoScrollSwitch.on = YES;
    }
    return _mAutoScrollSwitch;
}

- (UILabel *)mSwitchLabel {
    if (!_mSwitchLabel) {
        _mSwitchLabel = [[UILabel alloc] init];
        _mSwitchLabel.text = NSLocalizedString(@"自动滚动", nil);
        _mSwitchLabel.textAlignment = NSTextAlignmentCenter;
        _mSwitchLabel.font = [UIFont systemFontOfSize:13];
        _mSwitchLabel.textColor = [UIColor whiteColor];
    }
    return _mSwitchLabel;
}

- (UISearchBar *)mSearchBar {
    if (!_mSearchBar) {
        _mSearchBar = [[UISearchBar alloc] init];
        [_mSearchBar setPlaceholder:NSLocalizedString(@"内容过滤查找", nil)];
        [_mSearchBar setBarStyle:UIBarStyleDefault];
        [_mSearchBar setBackgroundImage:[UIImage new]];
        [_mSearchBar setBackgroundColor:[UIColor whiteColor]];
        _mSearchBar.delegate = self;
    }
    return _mSearchBar;
}

- (UIButton *)mPreviousButton {
    if (!_mPreviousButton) {
        _mPreviousButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mPreviousButton setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:118.0/255.0 blue:118.0/255.0 alpha:1.0]];
        [_mPreviousButton setTitle:NSLocalizedString(@"上一条", nil) forState:UIControlStateNormal];
        [_mPreviousButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_mPreviousButton setTitleColor:[UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0] forState:UIControlStateDisabled];
        [_mPreviousButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        _mPreviousButton.enabled = false;
    }
    return _mPreviousButton;
}

- (UIButton *)mNextButton {
    if (!_mNextButton) {
        _mNextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mNextButton setBackgroundColor:[UIColor colorWithRed:93.0/255.0 green:174.0/255.0 blue:139.0/255.0 alpha:1.0]];
        [_mNextButton setTitle:NSLocalizedString(@"下一条", nil) forState:UIControlStateNormal];
        [_mNextButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_mNextButton setTitleColor:[UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0] forState:UIControlStateDisabled];
        [_mNextButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        _mNextButton.enabled = false;
    }
    return _mNextButton;
}

- (UILabel *)mSearchNumLabel {
    if (!_mSearchNumLabel) {
        _mSearchNumLabel = [[UILabel alloc] init];
        _mSearchNumLabel.text = NSLocalizedString(@"0条结果", nil);
        _mSearchNumLabel.textAlignment = NSTextAlignmentCenter;
        _mSearchNumLabel.font = [UIFont systemFontOfSize:12];
        _mSearchNumLabel.textColor = [UIColor whiteColor];
        _mSearchNumLabel.backgroundColor = [UIColor colorWithRed:57.0/255.0 green:74.0/255.0 blue:81.0/255.0 alpha:1.0];
    }
    return _mSearchNumLabel;
}

- (UILabel *)mTipLabel {
    if (!_mTipLabel) {
        _mTipLabel = [[UILabel alloc] init];
        _mTipLabel.text = @"HDWindowLogger v2.0";
        _mTipLabel.textAlignment = NSTextAlignmentCenter;
        _mTipLabel.font = [UIFont systemFontOfSize:12];
        _mTipLabel.textColor = [UIColor whiteColor];
        _mTipLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0];
    }
    return _mTipLabel;
}

#pragma mark -
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mLogDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"loggerCellIdentifier";
    HDWindowLoggerItem *item = [self.mLogDataArray objectAtIndex:indexPath.row];
    
    HDLoggerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[HDLoggerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.row%2 != 0) {
        cell.backgroundColor = [UIColor colorWithRed:156.0/255.0 green:44.0/255.0 blue:44.0/255.0 alpha:0.8];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    [cell updateWithLoggerItem:item withHighlightText:self.mSearchBar.text];
    return cell;
}

#pragma mark -
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.00001f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.00001f;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HDWindowLoggerItem *item = [self.mLogDataArray objectAtIndex:indexPath.row];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [item getFullContentString];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *dateStr = [dateFormatter stringFromDate:item.mCreateDate];
    
    NSString *tipString = [NSString stringWithFormat:@"%@ %@",dateStr,NSLocalizedString(@"日志已拷贝到剪切板", nil)];
    HDWarnLog(tipString);
}

#pragma mark -
#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self p_reloadFilter];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [UIView performWithoutAnimation:^{
         [self.mTableView reloadRowsAtIndexPaths:self.mFilterIndexArray withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [textField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.mTextPassword = textField.text;
    [self p_decrypt];
}
@end
