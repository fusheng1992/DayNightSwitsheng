#import "DayNightSwitch.h"
#import <objc/runtime.h>

static const void *kFushengSwitchKey = &kFushengSwitchKey;
static NSDictionary *gPrefs = nil;

#pragma mark - 偏好读取

static UIColor *ColorFromHex(NSString *hex, UIColor *fallback) {
    if (!hex || hex.length == 0) return fallback;
    NSString *s = [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([s hasPrefix:@"#"]) s = [s substringFromIndex:1];
    if (s.length != 6) return fallback;
    
    unsigned int rgb = 0;
    NSScanner *scan = [NSScanner scannerWithString:s];
    if (![scan scanHexInt:&rgb]) return fallback;
    
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

static void LoadPrefs() {
    NSString *path = @"/var/jb/var/mobile/Library/Preferences/com.fusheng.daynightswitchfs.plist";
    gPrefs = [NSDictionary dictionaryWithContentsOfFile:path] ?: @{};
}

static BOOL IsEnabled() {
    id v = gPrefs[@"enabled"];
    return v ? [v boolValue] : YES;  // 默认开启
}

static void PrefsChanged(CFNotificationCenterRef center, void *observer, 
                         CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    LoadPrefs();
}

#pragma mark - Hook UISwitch

%hook UISwitch

- (void)didMoveToWindow {
    %orig;
    
    if (!IsEnabled()) return;
    if (self.window == nil) return;
    
    // 避免重复添加
    FushengDayNightSwitch *existing = objc_getAssociatedObject(self, kFushengSwitchKey);
    if (existing) return;
    
    // 隐藏原生 UISwitch
    self.alpha = 0.011;
    
    // 创建自定义 switch
    FushengDayNightSwitch *fs = [[FushengDayNightSwitch alloc] initWithFrame:self.bounds];
    fs.on = self.isOn;
    
    // 应用用户颜色
    NSString *dayHex = gPrefs[@"dayColor"];
    NSString *nightHex = gPrefs[@"nightColor"];
    if (dayHex) fs.dayBackgroundColor = ColorFromHex(dayHex, fs.dayBackgroundColor);
    if (nightHex) fs.nightBackgroundColor = ColorFromHex(nightHex, fs.nightBackgroundColor);
    
    // 联动：用户点击我们的 switch → 同步原生 UISwitch
    __weak UISwitch *weakOriginal = self;
    [fs addTarget:self action:@selector(fs_onValueChanged:) forControlEvents:UIControlEventValueChanged];
    objc_setAssociatedObject(fs, "weakOriginal", weakOriginal, OBJC_ASSOCIATION_ASSIGN);
    
    // 加到父视图（不加在 self 里，否则会被裁剪）
    UIView *superview = self.superview;
    if (superview) {
        fs.center = self.center;
        [superview addSubview:fs];
    } else {
        fs.frame = self.bounds;
        [self addSubview:fs];
    }
    
    objc_setAssociatedObject(self, kFushengSwitchKey, fs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (void)fs_onValueChanged:(FushengDayNightSwitch *)sender {
    // 同步状态到原生 UISwitch
    [self setOn:sender.isOn animated:NO];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    %orig;
    FushengDayNightSwitch *fs = objc_getAssociatedObject(self, kFushengSwitchKey);
    if (fs && fs.isOn != on) {
        [fs setOn:on animated:animated];
    }
}

- (void)setOn:(BOOL)on {
    %orig;
    FushengDayNightSwitch *fs = objc_getAssociatedObject(self, kFushengSwitchKey);
    if (fs && fs.isOn != on) {
        [fs setOn:on animated:NO];
    }
}

%end

#pragma mark - 构造函数

%ctor {
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL, PrefsChanged,
                                    CFSTR("com.fusheng.daynightswitchfs/reload"),
                                    NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}