//
//  LoggerTableViewCell.m
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import "HDLoggerTableViewCell.h"
#import "HDWindowLogger.h"

@interface HDLoggerTableViewCell ()
@property (strong, nonatomic) UILabel *mContentLabel;
@end

@implementation HDLoggerTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self p_createUI];
    }
    return self;
}

- (void)p_createUI {
    self.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.mContentLabel];
}

- (void)updateWithLoggerItem:(HDWindowLoggerItem *)item withSearchText:(NSString *)searchText {
    switch (item.mLogItemType) {
        case kHDLogTypeNormal: {
            [self.mContentLabel setTextColor:[UIColor colorWithRed:80.0/255.0 green:216.0/255.0 blue:144.0/255.0 alpha:1.0]];
        }
            break;
        case kHDLogTypeWarn: {
            [self.mContentLabel setTextColor:[UIColor colorWithRed:246.0/255.0 green:244.0/255.0 blue:157.0/255.0 alpha:1.0]];
        }
            break;
        case kHDLogTypeError: {
            [self.mContentLabel setTextColor:[UIColor colorWithRed:255.0/255.0 green:118.0/255.0 blue:118.0/255.0 alpha:1.0]];
        }
            break;
        case kHDLogTypePrivacy: {
                [self.mContentLabel setTextColor:[UIColor colorWithRed:66.0/255.0 green:230.0/255.0 blue:164.0/255.0 alpha:1.0]];
        }
            break;
    }
    
    if (searchText && searchText.length > 0) {
        NSString *contentString = [item getFullContentString];
        NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString: contentString];
        NSError *error;
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:searchText options:NSRegularExpressionCaseInsensitive error:&error];
        if (!error) {
            [self.mContentLabel setText:[item getFullContentString]];
        } else {
            [regex enumerateMatchesInString:contentString options:NSMatchingReportProgress range:NSMakeRange(0, [contentString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                [newString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0/255.0 green:0.0 blue:0.0 alpha:1.0] range:result.range];
                [self.mContentLabel setAttributedText: newString];
            }];
        }
    } else {
        [self.mContentLabel setText:[item getFullContentString]];
    }
    
    CGSize size = [self.mContentLabel sizeThatFits:CGSizeMake([UIScreen mainScreen].bounds.size.width, MAXFLOAT)];
    [self.mContentLabel setFrame:CGRectMake(0, 0, size.width, ceil(size.height) + 1)];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark -
#pragma mark - LazyLoad
- (UILabel *)mContentLabel {
    if (!_mContentLabel) {
        _mContentLabel = [[UILabel alloc] init];
        _mContentLabel.numberOfLines = 0;
        _mContentLabel.font = [UIFont systemFontOfSize:13];
    }
    return _mContentLabel;
}
@end
