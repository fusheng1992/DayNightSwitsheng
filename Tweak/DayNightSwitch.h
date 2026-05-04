#import <UIKit/UIKit.h>

@interface FushengDayNightSwitch : UIControl

@property (nonatomic, assign, getter=isOn) BOOL on;

// 颜色自定义（用户可修改）
@property (nonatomic, strong) UIColor *dayBackgroundColor;    // 白天背景色
@property (nonatomic, strong) UIColor *nightBackgroundColor;  // 夜晚背景色

- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end