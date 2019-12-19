//
//  HDWindowLogger.h
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HDWindowLoggerItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HDLogType) {
    kHDLogTypeNormal = 0,   //textColor #fbf2d5
    kHDLogTypeWarn,         //textColor #f6f49d
    kHDLogTypeError,        //textColor #ff7676
};

#pragma mark -
#pragma mark - 快捷宏定义输出类型
#define HDNormalLog(log) [HDWindowLogger printLog:log withLogType:kHDLogTypeNormal file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ functionName:[NSString stringWithFormat:@"%s",__FUNCTION__]]     //普通类型的输出
#define HDWarnLog(log) [HDWindowLogger printLog:log withLogType:kHDLogTypeWarn file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ functionName:[NSString stringWithFormat:@"%s",__FUNCTION__]]         //警告类型的输出
#define HDErrorLog(log) [HDWindowLogger printLog:log withLogType:kHDLogTypeError file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ functionName:[NSString stringWithFormat:@"%s",__FUNCTION__]]       //错误类型的输出

#pragma mark -
#pragma mark - HDWindowLogger
@interface HDWindowLogger : UIWindow
@property (strong, nonatomic, readonly) NSMutableArray *mLogDataArray;  //log信息内容
@property (assign, nonatomic) BOOL mCompleteLogOut;           //是否完整输出日志文件名等调试内容
@property (assign, nonatomic) BOOL mDebugAreaLogOut;           //是否在xcode底部的调试栏同步输出内容

+ (HDWindowLogger *)defaultWindowLogger;

/**
 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样

 @param log 日志内容
 @param logType 日志类型
 */
+ (void)printLog:(id)log withLogType:(HDLogType)logType DEPRECATED_MSG_ATTRIBUTE("请使用HDNormalLog等快捷宏定义输入");


///  根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
/// @param log 日志内容
/// @param logType 日志类型
/// @param fileName 调用输出的文件
/// @param line 调用输出的行数
/// @param funcationName 调用输出的函数名
+ (void)printLog:(id)log withLogType:(HDLogType)logType file:(NSString *)fileName line:(NSInteger)line functionName:(NSString *)funcationName;

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


/**
 为了节省内存，可以设置记录的最大的log数，超出限制删除最老的数据，默认不限制

 @param logCount 0为不限制
 */
+ (void)setMaxLogCount:(NSInteger)logCount;
@end

#pragma mark -
#pragma mark - 每个打印的item
@interface HDWindowLoggerItem : NSObject
@property (assign, nonatomic) HDLogType mLogItemType;
@property (strong, nonatomic) id mLogContent;
@property (strong, nonatomic) NSDate *mCreateDate;
///获取item的拼接的打印内容
- (NSString *)getFullContentString;
@end

NS_ASSUME_NONNULL_END
