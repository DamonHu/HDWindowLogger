//
//  HDWindowLogger.h
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HDLogType) {
    kHDLogTypeNormal = 0,   //textColor #fbf2d5
    kHDLogTypeWarn,         //textColor #f6f49d
    kHDLogTypeError,        //textColor #ff7676
};

#pragma mark -
#pragma mark - 快捷宏定义输出类型

#define HDNormalLog(log) [HDWindowLogger printLog:log withLogType:kHDLogTypeNormal]     //普通类型的输出
#define HDWarnLog(log) [HDWindowLogger printLog:log withLogType:kHDLogTypeWarn]         //警告类型的输出
#define HDErrorLog(log) [HDWindowLogger printLog:log withLogType:kHDLogTypeError]       //错误类型的输出


#pragma mark -
#pragma mark - 每个打印的item
@interface HDWindowLoggerItem : NSObject
@property (assign, nonatomic) HDLogType mLogItemType;
@property (copy, nonatomic) NSString *mLogContent;
@property (strong, nonatomic) NSDate *mCreateDate;
@end

#pragma mark -
#pragma mark - 打印的视图
@interface HDWindowLogger : UIWindow

/**
 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样

 @param log 日志内容
 @param logType 日志类型
 */
+ (void)printLog:(id)log withLogType:(HDLogType)logType;

/**
 删除log日志
 */
+ (void)cleanLog;

/**
 显示log窗口
 */
+ (void)show;


/**
 隐藏整个log窗口
 */
+ (void)hide;


/**
 只隐藏log的输出窗口，保留悬浮图标
 */
+ (void)hideLogWindow;
@end

NS_ASSUME_NONNULL_END
