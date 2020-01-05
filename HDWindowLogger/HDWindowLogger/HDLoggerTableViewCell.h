//
//  LoggerTableViewCell.h
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HDWindowLoggerItem;

NS_ASSUME_NONNULL_BEGIN

@interface HDLoggerTableViewCell : UITableViewCell

- (void)updateWithLoggerItem:(HDWindowLoggerItem *)item withHighlightText:(NSString *)highlightText;
@end

NS_ASSUME_NONNULL_END
