//
//  HDWindowLogger.m
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import "HDWindowLogger.h"
#import "HDLoggerTableViewCell.h"


@implementation HDWindowLoggerItem
///获取item的拼接的打印内容
- (NSString *)getFullContentString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *dateStr = [dateFormatter stringFromDate:self.mCreateDate];
    NSString *contentString = [NSString stringWithFormat:@"%@   >     %@",dateStr,self.mLogContent];
    return contentString;
}
@end

#pragma mark -
#pragma mark - HDWindowLogger
@interface HDWindowLogger () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (strong, nonatomic, readwrite) NSMutableArray *mLogDataArray;  //log信息内容
@property (strong, nonatomic) NSMutableArray *mFilterLogDataArray;       //展示的筛选的log信息内容
@property (assign, nonatomic) NSInteger mMaxLogCount;      //最大数

@property (strong, nonatomic) UIView *mBGView;
@property (strong, nonatomic) UITableView *mTableView;
@property (strong, nonatomic) UIButton *mCleanButton;
@property (strong, nonatomic) UIButton *mHideButton;
@property (strong, nonatomic) UIButton *mShareButton;
@property (strong, nonatomic) UIWindow *mFloatWindow;
@property (strong, nonatomic) UILabel *mSwitchLabel;
@property (strong, nonatomic) UISwitch *mAutoScrollSwitch; //输出日志自动滚动
@property (strong, nonatomic) UISearchBar *mSearchBar;
@end

@implementation HDWindowLogger

#pragma mark -
#pragma mark - init Method
+ (HDWindowLogger *)defaultWindowLogger {
    static HDWindowLogger *defaultLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultLogger = [[HDWindowLogger alloc] init];
        defaultLogger.mMaxLogCount = 100;
    });
    return defaultLogger;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 300)];
    if (self) {
        [self p_createUI];
        [self p_bindClick];
    }
    return self;
}

#pragma mark -
#pragma mark - Public Method

/**
 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
 
 @param log 日志内容
 @param logType 日志类型
 */
+ (void)printLog:(id)log withLogType:(HDLogType)logType {
    if ([self defaultWindowLogger].mLogDataArray.count == 0) {
        //如果是第一条，就插入一条默认帮助提示
        HDWindowLoggerItem *item = [[HDWindowLoggerItem alloc] init];
        item.mLogItemType = kHDLogTypeWarn;
        item.mCreateDate = [NSDate date];
        item.mLogContent = NSLocalizedString(@"HDWindowLogger: 点击对应日志可快速复制", nil);
        [[self defaultWindowLogger].mLogDataArray addObject:item];
    }
    HDWindowLoggerItem *item = [[HDWindowLoggerItem alloc] init];
    item.mLogItemType = logType;
    item.mCreateDate = [NSDate date];
    item.mLogContent = log;
    [[self defaultWindowLogger].mLogDataArray addObject:item];
    if ([self defaultWindowLogger].mMaxLogCount > 0 && [self defaultWindowLogger].mLogDataArray.count > [self defaultWindowLogger].mMaxLogCount) {
        [[self defaultWindowLogger].mLogDataArray removeObjectAtIndex:0];
    }
    [[self defaultWindowLogger] p_reloadFilter];
}

/**
 删除log日志
 */
+ (void)cleanLog {
    [[self defaultWindowLogger].mLogDataArray removeAllObjects];
    [[self defaultWindowLogger].mFilterLogDataArray removeAllObjects];
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
 为了节省内存，可以设置记录的最大的log数，超出限制删除最老的数据，默认100条
 
 @param logCount 0为不限制
 */
+ (void)setMaxLogCount:(NSInteger)logCount {
    [self defaultWindowLogger].mMaxLogCount = logCount;
}

#pragma mark -
#pragma mark - Private Method
- (void)p_createUI {
    self.rootViewController = [UIViewController new]; // suppress warning
    self.windowLevel = UIWindowLevelAlert;
    [self setBackgroundColor:[UIColor clearColor]];
    self.userInteractionEnabled = YES;
    
    ///添加主视图
    [self.rootViewController.view addSubview:self.mBGView];
    [self.mBGView setFrame:self.bounds];
    
    //按钮
    [self.mBGView addSubview:self.mHideButton];
    [self.mHideButton setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width/3.0, 40)];
    [self.mBGView addSubview:self.mShareButton];
    [self.mShareButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/3.0, 0, [UIScreen mainScreen].bounds.size.width/3.0, 40)];
    [self.mBGView addSubview:self.mCleanButton];
    [self.mCleanButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width*2/3.0, 0, [UIScreen mainScreen].bounds.size.width/3.0, 40)];
    
    //滚动日志窗
    [self.mBGView addSubview:self.mTableView];
    [self.mTableView setFrame:CGRectMake(0, 40, [UIScreen mainScreen].bounds.size.width, 300 - 80)];
    
    //开关视图
    [self.mBGView addSubview:self.mAutoScrollSwitch];
    [self.mAutoScrollSwitch setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width- 60, 40, 60, 40)];
    [self.mBGView addSubview:self.mSwitchLabel];
    [self.mSwitchLabel setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width- 155, 40, 90, 30)];
    
    [self.mBGView addSubview:self.mSearchBar];
    [self.mSearchBar setFrame:CGRectMake(0, 300 - 40, [UIScreen mainScreen].bounds.size.width, 40)];
}

- (void)p_bindClick {
    [self.mHideButton addTarget:self action:@selector(p_hideLogWindow) forControlEvents:UIControlEventTouchUpInside];
    [self.mCleanButton addTarget:self action:@selector(p_cleanLog) forControlEvents:UIControlEventTouchUpInside];
    [self.mShareButton addTarget:self action:@selector(p_share) forControlEvents:UIControlEventTouchUpInside];
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
    
    //生成文件需要的内容
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (HDWindowLoggerItem *item in self.mLogDataArray) {
        NSString *dateStr = [dateFormatter stringFromDate:item.mCreateDate];
        [mutableArray addObject:dateStr];
        [mutableArray addObject: item.mLogContent];
    }
    //写入文件
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableArray options:NSJSONWritingPrettyPrinted error:nil];
    [jsonData writeToFile:logFilePath atomically:YES];
    
    //分享
    NSURL *url = [NSURL fileURLWithPath:logFilePath];
    
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:url,jsonData, nil] applicationActivities:nil];
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

///更新筛选数据
- (void)p_reloadFilter {
    [self.mFilterLogDataArray removeAllObjects];
    for (HDWindowLoggerItem *item in self.mLogDataArray) {
        if (self.mSearchBar.text.length > 0) {
            if ([[item getFullContentString] containsString:self.mSearchBar.text]) {
                [self.mFilterLogDataArray addObject:item];
            }
        } else {
            [self.mFilterLogDataArray addObject:item];
        }
        [self.mTableView reloadData];
        if (self.mFilterLogDataArray.count > 0 && self.mAutoScrollSwitch.isOn) {
            [self.mTableView  scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.mFilterLogDataArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }
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

- (NSMutableArray *)mFilterLogDataArray {
    if (!_mFilterLogDataArray) {
        _mFilterLogDataArray = [NSMutableArray array];
    }
    return _mFilterLogDataArray;
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
    }
    return _mTableView;
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


- (UIWindow *)mFloatWindow {
    if (!_mFloatWindow) {
        _mFloatWindow = [[UIWindow alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 70, 50, 60, 60)];
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
        _mSwitchLabel.text = NSLocalizedString(@"日志自动滚动", nil);
        _mSwitchLabel.textAlignment = NSTextAlignmentRight;
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
        [_mSearchBar setBackgroundColor:[UIColor clearColor]];
        _mSearchBar.delegate = self;
    }
    return _mSearchBar;
}

#pragma mark -
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mFilterLogDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"loggerCellIdentifier";
    HDWindowLoggerItem *item = [self.mFilterLogDataArray objectAtIndex:indexPath.row];
    
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
    [cell updateWithLoggerItem:item];
    return cell;
}

#pragma mark -
#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    HDWindowLoggerItem *item = [self.mFilterLogDataArray objectAtIndex:indexPath.row];
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:13];
    [label setText:[item getFullContentString]];
    CGSize size = [label sizeThatFits:CGSizeMake([UIScreen mainScreen].bounds.size.width, MAXFLOAT)];
    return ceil(size.height) + 1;
}

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
    HDWindowLoggerItem *item = [self.mFilterLogDataArray objectAtIndex:indexPath.row];
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
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
@end
