//
//  HDWindowLoggerItem.m
//  HDWindowLogger
//
//  Created by Damon on 2020/7/20.
//  Copyright © 2020 Damon. All rights reserved.
//

#import "HDWindowLoggerItem.h"
#import "HDWindowLogger.h"
#import <CommonCrypto/CommonCryptor.h>

@interface HDWindowLoggerItem ()
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
    
    if ([NSJSONSerialization isValidJSONObject:self.mLogContent]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.mLogContent
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (!jsonData) {
            contentString = [self unicodeDecodeWithString:[NSString stringWithFormat:@"%@",self.mLogContent]];
        } else {
            contentString = [self unicodeDecodeWithString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
        }
    } else {
        contentString = [self unicodeDecodeWithString:[NSString stringWithFormat:@"%@",self.mLogContent]];
    }
    if (self.mLogItemType == kHDLogTypePrivacy) {
        if (HDWindowLogger.defaultWindowLogger.mPrivacyPassword.length == 0) {
            contentString = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"密码设置长度错误，需要32个字符", comment: @""), contentString];
        } else if (HDWindowLogger.defaultWindowLogger.mPrivacyPassword.length != kCCKeySizeAES256) {
            contentString = NSLocalizedString(@"密码设置长度错误，需要32个字符", comment: @"");
        } else if (!HDWindowLogger.defaultWindowLogger.mPasswordCorrect) {
            contentString = [[self p_cryptWithData: [self.mLogContent dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        }
    }
    if (HDWindowLogger.defaultWindowLogger.mCompleteLogOut) {
        return [NSString stringWithFormat:@"%@   >     %@\n%@\n",dateStr, self.mLogDebugContent, contentString];
    } else {
        return [NSString stringWithFormat:@"%@   >     %@\n",dateStr,contentString];
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

///unicode转字符串
- (NSString *)unicodeDecodeWithString:(NSString *)string {
    NSString *tempStr1=[string stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2=[tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3=[[@"\"" stringByAppendingString:tempStr2]stringByAppendingString:@"\""];
    NSData *tempData=[tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSString* returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:&error];
    if (!error) {
        return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
    } else {
        return string;
    }
}

//内容加密
- (NSData *)p_cryptWithData:(NSData *)data {
    NSString *ivString = @"abcdefghijklmnop";
    
    NSData *keyData = [HDWindowLogger.defaultWindowLogger.mPrivacyPassword dataUsingEncoding:NSUTF8StringEncoding];
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
@end
