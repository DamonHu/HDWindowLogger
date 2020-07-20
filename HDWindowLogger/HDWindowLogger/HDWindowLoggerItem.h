//
//  HDWindowLoggerItem.h
//  HDWindowLogger
//
//  Created by Damon on 2020/7/20.
//  Copyright © 2020 Damon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HDLogType) {
    kHDLogTypeNormal = 0,   //textColor #50d890
    kHDLogTypeWarn,         //textColor #f6f49d
    kHDLogTypeError,        //textColor #ff7676
    kHDLogTypePrivacy       //textColor #42e6a4
};


NS_ASSUME_NONNULL_BEGIN

typedef void (^HighlightComplete)(BOOL hasHighlightStr, NSAttributedString *hightlightAttributedString);

@interface HDWindowLoggerItem : NSObject
@property (assign, nonatomic) HDLogType mLogItemType;
@property (strong, nonatomic) id mLogContent;
@property (copy, nonatomic) NSString *mLogDebugContent;
@property (strong, nonatomic) NSDate *mCreateDate;

///获取item的拼接的打印内容
- (NSString *)getFullContentString;

///设置需要高亮的字符串
- (void)getHighlightCompleteString:(NSString *)highlightString complete:(HighlightComplete)complete;
@end

NS_ASSUME_NONNULL_END
