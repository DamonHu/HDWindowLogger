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

@interface HDWindowLoggerItem ()
@property (assign, nonatomic) CGFloat mCellHeight;  //内容的cell高度
@property (copy, nonatomic) NSString *mCurrentHighlightString; //当前需要高亮的字符串
@property (assign, nonatomic) BOOL mCacheHasHighlightString;  //是否包含需要高亮的字符串
@property (copy, nonatomic) NSAttributedString *mCacheHighlightCompleteString; //包含高亮字符的富文本
@end

@implementation HDWindowLoggerItem
///获取item的拼接的打印内容
- (NSString *)getFullContentString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *dateStr = [dateFormatter stringFromDate:self.mCreateDate];
    //内容
    NSString *contentString = @"";
    if (self.mLogItemType == kHDLogTypePrivacy) {
        if ([NSJSONSerialization isValidJSONObject:self.mLogContent]) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.mLogContent
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&error];
            if (!jsonData) {
                contentString = [NSString stringWithFormat:@"%@",self.mLogContent];
            } else {
                contentString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        } else {
            contentString = [NSString stringWithFormat:@"%@",self.mLogContent];
        }
        if (!HDWindowLogger.defaultWindowLogger.mPasswordCorrect) {
            contentString = NSLocalizedString(@"该内容已加密，请解密后查看", comment: @"");
        }
        if (HDWindowLogger.defaultWindowLogger.mPrivacyPassword.length > 0 && HDWindowLogger.defaultWindowLogger.mPrivacyPassword.length != kCCKeySizeAES256) {
            contentString = NSLocalizedString(@"密码设置长度错误，需要32个字符", comment: @"");
        }
    } else {
        if ([NSJSONSerialization isValidJSONObject:self.mLogContent]) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.mLogContent
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&error];
            if (!jsonData) {
                contentString = [NSString stringWithFormat:@"%@",self.mLogContent];
            } else {
                contentString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        } else {
            contentString = [NSString stringWithFormat:@"%@",self.mLogContent];
        }
    }
    if (HDWindowLogger.defaultWindowLogger.mCompleteLogOut) {
        return [NSString stringWithFormat:@"%@   >     %@\n%@",dateStr, self.mLogDebugContent, contentString];
    } else {
        return [NSString stringWithFormat:@"%@   >     %@",dateStr,contentString];
    }
}

- (CGFloat)mCellHeight {
    if (_mCellHeight == 0) {
        NSString *contentString = [self getFullContentString];
        NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString: contentString attributes: [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:13] ,NSFontAttributeName, nil]];
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        [label setAttributedText:newString];
        _mCellHeight = ceil([label sizeThatFits:CGSizeMake([UIScreen mainScreen].bounds.size.width, MAXFLOAT)].height) + 1;
        return _mCellHeight;
    } else {
        return _mCellHeight;
    }
}

- (void)getHighlightCompleteString:(NSString *)highlightString complete:(HighlightComplete)complete {
    if (!highlightString || highlightString.length == 0) {
        NSString *contentString = [self getFullContentString];
        NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString: contentString attributes: [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:13] ,NSFontAttributeName, nil]];
        self.mCacheHighlightCompleteString = newString;
        self.mCacheHasHighlightString = false;
        complete(self.mCacheHasHighlightString, newString);
    } else if ([highlightString isEqualToString:self.mCurrentHighlightString]) {
        //和上次高亮相同，直接用之前的回调
        complete(self.mCacheHasHighlightString, self.mCacheHighlightCompleteString);
    } else {
        self.mCurrentHighlightString = highlightString;
        NSString *contentString = [self getFullContentString];
        NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString: contentString attributes: [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:13] ,NSFontAttributeName, nil]];
        NSError *error;
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:highlightString options:NSRegularExpressionCaseInsensitive error:&error];
        if (error) {
            self.mCacheHighlightCompleteString = newString;
            self.mCacheHasHighlightString = false;
            complete(self.mCacheHasHighlightString, newString);
        } else {
            self.mCacheHasHighlightString = false;
            [regex enumerateMatchesInString:contentString options:NSMatchingReportCompletion range:NSMakeRange(0, [contentString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                [newString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0/255.0 green:0.0 blue:0.0 alpha:1.0] range:result.range];
                if (result != nil) {
                    self.mCacheHasHighlightString = true;
                }
                self.mCacheHighlightCompleteString = newString;
                complete(self.mCacheHasHighlightString, newString);
            }];
        }
    }
}
@end

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
@property (strong, nonatomic) UIButton *mHideButton;
@property (strong, nonatomic) UIButton *mShareButton;
@property (strong, nonatomic) UIWindow *mFloatWindow;
@property (strong, nonatomic) UILabel *mSwitchLabel;
@property (strong, nonatomic) UISwitch *mAutoScrollSwitch; //输出自动滚动
@property (strong, nonatomic) UISearchBar *mSearchBar;
@property (strong, nonatomic) UIButton *mPreviousButton;      //上一条
@property (strong, nonatomic) UIButton *mNextButton;          //下一条
@property (strong, nonatomic) UILabel *mSearchNumLabel;       //搜索条数
@property (assign, nonatomic) NSInteger mCurrentSearchIndex;  //当前搜索到的索引
@end

@implementation HDWindowLogger

#pragma mark -
#pragma mark - init Method
+ (HDWindowLogger *)defaultWindowLogger {
    static HDWindowLogger *defaultLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 13.0, *)) {
            if ([UIApplication sharedApplication].connectedScenes.count > 0) {
                UIWindowScene *scene = [[[UIApplication sharedApplication].connectedScenes allObjects] firstObject];
                defaultLogger = [[HDWindowLogger alloc] initWithWindowScene:scene];
            }
        }
        if (!defaultLogger) {
            defaultLogger = [[HDWindowLogger alloc] init];
        }
        defaultLogger.mMaxLogCount = 0;
        defaultLogger.mCompleteLogOut = true;
        defaultLogger.mDebugAreaLogOut = true;
        defaultLogger.mPrivacyPassword = @"";
        defaultLogger.mTextPassword = @"";
    });
    return defaultLogger;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            float statusBarHeight = 0;
            if (@available(iOS 13.0, *)) {
                statusBarHeight = self.windowScene.statusBarManager.statusBarFrame.size.height;
                if (statusBarHeight == 0) {
                    statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
                }
            } else {
                statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
            }
            [self setFrame:CGRectMake(0, statusBarHeight, [UIScreen mainScreen].bounds.size.width, 342)];
            self.rootViewController = [UIViewController new]; // suppress warning
            self.windowLevel = UIWindowLevelStatusBar;
            [self setBackgroundColor:[UIColor clearColor]];
            self.userInteractionEnabled = YES;
            [self p_createUI];
            [self p_bindClick];
        });
    }
    return self;
}

#ifdef __IPHONE_13_0
- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    self = [super initWithWindowScene:windowScene];
    if (self) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                   float statusBarHeight = self.windowScene.statusBarManager.statusBarFrame.size.height;
                   if (statusBarHeight == 0) {
                       statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
                   }
                   [self setFrame:CGRectMake(0, statusBarHeight, [UIScreen mainScreen].bounds.size.width, 342)];
                   self.rootViewController = [UIViewController new]; // suppress warning
                   self.windowLevel = UIWindowLevelStatusBar;
                   [self setBackgroundColor:[UIColor clearColor]];
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
    //解密
    [self.mBGView addSubview:self.mPasswordTextField];
    self.mPasswordTextField.frame = CGRectMake(0, 40, [UIScreen mainScreen].bounds.size.width/3.0 + 50, 40);
    [self.mBGView addSubview:self.mPasswordButton];
    self.mPasswordButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/3.0 + 50, 40, [UIScreen mainScreen].bounds.size.width/3.0 - 50, 40);
    //开关视图
    [self.mBGView addSubview:self.mSwitchLabel];
    [self.mSwitchLabel setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width * 2.0 /3.0 + 6, 40, 90, 40)];
    [self.mBGView addSubview:self.mAutoScrollSwitch];
    [self.mAutoScrollSwitch setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 60, 45, 60, 40)];
    
    //滚动日志窗
    [self.mBGView addSubview:self.mTableView];
    [self.mTableView setFrame:CGRectMake(0, 80, [UIScreen mainScreen].bounds.size.width, 220)];
    
    //搜索
    [self.mBGView addSubview:self.mSearchBar];
    [self.mSearchBar setFrame:CGRectMake(0, 300, [UIScreen mainScreen].bounds.size.width - 180, 40)];
    //
    [self.mBGView addSubview:self.mPreviousButton];
    [self.mPreviousButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 180, 300, 60, 40)];
    
    [self.mBGView addSubview:self.mNextButton];
    [self.mNextButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 120, 300, 60, 40)];
    
    [self.mBGView addSubview:self.mSearchNumLabel];
    [self.mSearchNumLabel setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 60, 300, 60, 40)];
}

- (void)p_bindClick {
    [self.mHideButton addTarget:self action:@selector(p_hideLogWindow) forControlEvents:UIControlEventTouchUpInside];
    [self.mCleanButton addTarget:self action:@selector(p_cleanLog) forControlEvents:UIControlEventTouchUpInside];
    [self.mShareButton addTarget:self action:@selector(p_share) forControlEvents:UIControlEventTouchUpInside];
    [self.mPasswordButton addTarget:self action:@selector(p_decrypt) forControlEvents:UIControlEventTouchUpInside];
    [self.mPreviousButton addTarget:self action:@selector(p_previous) forControlEvents:UIControlEventTouchUpInside];
    [self.mNextButton addTarget:self action:@selector(p_next) forControlEvents:UIControlEventTouchUpInside];
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
        //单独写内容是为了文件换行
        NSString *dateStr = [dateFormatter stringFromDate:item.mCreateDate];
        [mutableArray addObject:[NSString stringWithFormat:@"%@  >  %@",dateStr, item.mLogDebugContent]];
        [mutableArray addObject: item.mLogContent];
    }
    //写入文件
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableArray options:NSJSONWritingPrettyPrinted error:nil];
    
    if (HDWindowLogger.defaultWindowLogger.mPasswordCorrect) {
        [jsonData writeToFile:logFilePath atomically:YES];
    } else {
        NSData *data = [self p_cryptWithData:jsonData];
        NSString *dataString = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        [dataString writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    
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

//内容加密
- (NSData *)p_cryptWithData:(NSData *)data {
    NSString *ivString = @"abcdefghijklmnop";
    
    NSData *keyData = [self.mPrivacyPassword dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [ivString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCKeySizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                          [keyData bytes], kCCKeySizeAES256,
                                          [ivData bytes] /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
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
        _mPasswordButton.backgroundColor = [UIColor colorWithRed:66.0/255.0 green:230.0/255.0 blue:164.0/255.0 alpha:1.0];
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
        _mSwitchLabel.textAlignment = NSTextAlignmentLeft;
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
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    HDWindowLoggerItem *item = [self.mLogDataArray objectAtIndex:indexPath.row];
    return item.mCellHeight;
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
    [textField resignFirstResponder];
    self.mTextPassword = textField.text;
    [self p_decrypt];
    return  true;
}
@end
