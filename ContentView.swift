#import "IKOBlueAndWhiteButtonBottomView.h"
#import "UIView+LabelConfiguration.h"
#import <DesignSystemTokens/DesignSystemTokens-Swift.h>
#import <DesignSystemUIKit/DesignSystemUIKit-Swift.h>
#import <UIComponents/UIComponents-Swift.h>

@implementation IKOBlueAndWhiteButtonBottomView

@synthesize additionalContentView = _additionalContentView;

- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle
                       whiteButtonTitle:(NSString *)whiteButtonTitle {
    return [self initWithBlueButtonTitle:blueButtonTitle whiteButtonTitle:whiteButtonTitle secondWhiteButtonTitle:nil hint:nil];
}

- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle andSeparator:(BOOL)showSeparator {
    return [self initWithBlueButtonTitle:blueButtonTitle whiteButtonTitle:whiteButtonTitle secondWhiteButtonTitle:nil hint:nil hintConfiguration:nil andSeparator:showSeparator];
}

- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle
                       whiteButtonTitle:(NSString *)whiteButtonTitle
                                   hint:(NSString *)hint {
    return [self initWithBlueButtonTitle:blueButtonTitle whiteButtonTitle:whiteButtonTitle secondWhiteButtonTitle:nil hint:hint];

}

- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle
                       whiteButtonTitle:(NSString *)whiteButtonTitle
                 secondWhiteButtonTitle:(NSString *)secondWhiteButtonTitle {
    return [self initWithBlueButtonTitle:blueButtonTitle whiteButtonTitle:whiteButtonTitle secondWhiteButtonTitle:secondWhiteButtonTitle hint:nil hintConfiguration:nil andSeparator:NO];
}

- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle secondWhiteButtonTitle:(NSString *)secondWhiteButtonTitle hint:(NSString *)hint {
    return [self initWithBlueButtonTitle:blueButtonTitle whiteButtonTitle:whiteButtonTitle secondWhiteButtonTitle:secondWhiteButtonTitle hint:hint hintConfiguration:[self smallLightGrayConfiguration] andSeparator:NO];
}

- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle
                       whiteButtonTitle:(NSString *)whiteButtonTitle
                 secondWhiteButtonTitle:(NSString *)secondWhiteButtonTitle
                                   hint:(NSString *)hint
                      hintConfiguration:(void (^)(Label *))configuration
                           andSeparator:(BOOL)showSeparator {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _useBottomSafeAreaGuide = YES;

        if (hint) {
            _hintLabel = [[[[Label fontWeight:lightWeight size:size16LS24] alignment:NSTextAlignmentCenter] multiline] textColor:ikoGray140];

            if (configuration) {
                configuration(_hintLabel);
            }

            _hintLabel.text = hint;
            [self addSubview:_hintLabel];
        }

        if (secondWhiteButtonTitle) {
            _secondWhiteButton = [IKOButton buttonWithLegacyType:IKOButtonLegacyTypeBigWhite];
            [_secondWhiteButton setTitle:secondWhiteButtonTitle forState:UIControlStateNormal];
            [self addSubview:_secondWhiteButton];
        }

        _blueButton = [IKOButton buttonWithLegacyType:IKOButtonLegacyTypeBigBlue];
        [_blueButton setTitle:blueButtonTitle forState:UIControlStateNormal];
        [self addSubview:_blueButton];

        _whiteButton = [IKOButton buttonWithLegacyType:IKOButtonLegacyTypeBigWhite];
        [_whiteButton setTitle:whiteButtonTitle forState:UIControlStateNormal];
        _whiteButton.hidden = whiteButtonTitle == nil;
        [self addSubview:_whiteButton];

        _order = IKOBlueAndWhiteButtonOrderWhiteFirst;

        if (showSeparator) {
            self.backgroundColor = UIColor.ikoWhite100;
            _separator = [UIView ikoSeparatorView];
            [self addSubview:_separator];
        }
    }

    return self;
}

- (void)updateConstraints {
    CGFloat horizontalMargin = IKOViewSizeMediumMargin;
    CGFloat topMargin = IKOViewSizeMediumMargin;

    UIView *firstView;
    UIView *secondView;
    UIView *secondWhiteButtonRightButtonView;

    if(self.separator){
        [self.separator mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self);
            make.height.equalTo(@(IKOViewSizeSeparatorDefaultHeight));
        }];
    }

    if (_order == IKOBlueAndWhiteButtonOrderBlueFirst || _order == IKOBlueAndWhiteButtonOrderHorizontalBlueFirst) {
        firstView = _blueButton;
        secondView = _whiteButton;
        secondWhiteButtonRightButtonView = secondView;
    } else if (_order == IKOBlueAndWhiteButtonOrderWhiteFirst || _order == IKOBlueAndWhiteButtonOrderHorizontalWhiteFirst) {
        firstView = _whiteButton;
        secondView = _blueButton;
        secondWhiteButtonRightButtonView = firstView;
    }

    if (self.additionalContentView) {
        [self.additionalContentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(topMargin);
            make.left.equalTo(self).offset(horizontalMargin);
            make.right.equalTo(self).offset(-horizontalMargin);
        }];
    }

    [self.hintLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (self.additionalContentView) {
            make.top.equalTo(self.additionalContentView.mas_bottom).offset(topMargin);
        } else {
            make.top.equalTo(self).offset(topMargin);
        }
        make.left.equalTo(self).offset(horizontalMargin);
        make.right.equalTo(self).offset(-horizontalMargin);
    }];

    [firstView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(horizontalMargin);
        if ([self isHorizontalOrder]) {
            make.right.equalTo(self.mas_centerX).offset(-horizontalMargin / 2.f);
            make.height.equalTo(secondView);
        } else if (!(_secondWhiteButton && _order == IKOBlueAndWhiteButtonOrderWhiteFirst)) {
            make.right.equalTo(self.mas_right).offset(-horizontalMargin);
            make.height.equalTo(@(kBlueButtonHeight));
        }

        if (self.hintLabel) {
            make.top.equalTo(self.hintLabel.mas_bottom).offset(topMargin);
        } else {
            if (self.additionalContentView) {
                make.top.equalTo(self.additionalContentView.mas_bottom).offset(topMargin);
            } else {
                make.top.equalTo(self.mas_top).offset(topMargin);
            }
        }
    }];

    [self.secondWhiteButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-horizontalMargin);
        make.top.bottom.equalTo(secondWhiteButtonRightButtonView);
        make.left.equalTo(secondWhiteButtonRightButtonView.mas_right).offset(horizontalMargin);
        make.width.equalTo(secondWhiteButtonRightButtonView.mas_width);
    }];

    [secondView mas_updateConstraints:^(MASConstraintMaker *make) {
        if ([self isHorizontalOrder]) {
            make.top.equalTo(firstView);
            make.left.equalTo(self.mas_centerX).offset(horizontalMargin / 2.f);
            make.height.equalTo(firstView);
        } else {
            make.left.equalTo(self.mas_left).offset(horizontalMargin);
            make.top.equalTo(firstView.mas_bottom).offset(topMargin);
            make.height.equalTo(@(kBlueButtonHeight));
        }
        make.right.equalTo(self.mas_right).offset(-horizontalMargin);
        if (_useBottomSafeAreaGuide) {
            make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-topMargin);
        } else {
            make.bottom.equalTo(self.mas_bottom).offset(-topMargin);
        }
    }];

    [super updateConstraints];
}

- (BOOL)isHorizontalOrder {
    return _order == IKOBlueAndWhiteButtonOrderHorizontalBlueFirst || _order == IKOBlueAndWhiteButtonOrderHorizontalWhiteFirst;
}

- (void)setAdditionalContentView:(UIView *)additionalContentView {
    if (!additionalContentView) {
        [_additionalContentView removeFromSuperview];
        _additionalContentView = nil;
        [self setNeedsUpdateConstraints];
        return;
    }

    _additionalContentView = [UIView new];
    _additionalContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.additionalContentView];
    [self.additionalContentView addSubview:additionalContentView];
    [additionalContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.additionalContentView);
    }];

    [self setNeedsUpdateConstraints];
}

- (void)lock {
    self.blueButton.enabled = NO;
}

- (void)unlock {
    self.blueButton.enabled = YES;
}

@end











#import "IKOAdditionalContentView.h"
#import "IKOBaseView.h"
#import "IKOLockableView.h"
#import <Foundation/Foundation.h>

@class IKOButton;
@class Label;

@interface IKOBlueAndWhiteButtonBottomView : IKOBaseView <IKOAdditionalContentView, IKOLockableView>

@property(nonatomic, strong) IKOButton *whiteButton;
@property(nonatomic, strong) IKOButton *secondWhiteButton;
@property(nonatomic, strong) IKOButton *blueButton;
@property(nonatomic, strong) Label *hintLabel;
@property(nonatomic, assign) IKOBlueAndWhiteButtonOrder order;
@property(nonatomic, strong) UIView *separator;
@property(nonatomic) BOOL useBottomSafeAreaGuide;

- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle NS_SWIFT_NAME(init(blueButtonTitle:whiteButtonTitle:));
- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle andSeparator:(BOOL)showSeparator NS_SWIFT_NAME(init(blueButtonTitle:whiteButtonTitle:showSeparator:));
- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle hint:(NSString *)hint;
- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle secondWhiteButtonTitle:(NSString *)secondWhiteButtonTitle;
- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle secondWhiteButtonTitle:(NSString *)secondWhiteButtonTitle hint:(NSString *)hint;
- (instancetype)initWithBlueButtonTitle:(NSString *)blueButtonTitle whiteButtonTitle:(NSString *)whiteButtonTitle secondWhiteButtonTitle:(NSString *)secondWhiteButtonTitle hint:(NSString *)hint hintConfiguration:(void (^)(Label *))configuration andSeparator:(BOOL)showSeparator;
@end
