//
//  LoggerTableViewCell.m
//  HDWindowLogger
//
//  Created by Damon on 2019/5/28.
//  Copyright © 2019 Damon. All rights reserved.
//

#import "HDLoggerTableViewCell.h"
#import "HDWindowLogger.h"
#import "Masonry.h"

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
    [self.mContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.right.equalTo(self.contentView).offset(-10);
        make.top.bottom.equalTo(self.contentView);
    }];

}

- (void)updateWithLoggerItem:(HDWindowLoggerItem *)item withHighlightText:(NSString *)highlightText {
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
    
    [item getHighlightCompleteString:highlightText complete:^(BOOL hasHighlightStr, NSAttributedString * _Nonnull hightlightAttributedString) {
        [self.mContentLabel setAttributedText:hightlightAttributedString];
        if (hasHighlightStr) {
            self.contentView.backgroundColor = [UIColor colorWithRed:145.0/255.0 green:109.0/255.0 blue:213.0/255.0 alpha:1.0];
        } else {
            self.contentView.backgroundColor = [UIColor clearColor];
        }
    }];
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
