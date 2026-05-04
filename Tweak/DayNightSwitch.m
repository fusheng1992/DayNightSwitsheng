#import "DayNightSwitch.h"

@implementation FushengDayNightSwitch {
    UIView *_backgroundView;        // 代码画的背景胶囊
    UIImageView *_animView;         // 帧动画视图
    NSArray<UIImage *> *_dayToNightFrames;  // 0~23：白→夜
    NSArray<UIImage *> *_nightToDayFrames;  // 24~47：夜→白
    BOOL _isAnimating;
}

@synthesize on = _on;

#pragma mark - 生命周期

- (instancetype)initWithFrame:(CGRect)frame {
    if (CGRectIsEmpty(frame)) {
        frame = CGRectMake(0, 0, 51, 31);
    }
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupDefaults];
        [self _setupViews];
        [self _loadFrames];
        [self _refreshDisplay];
    }
    return self;
}

- (void)_setupDefaults {
    _on = NO;
    _isAnimating = NO;
    _dayBackgroundColor   = [UIColor colorWithRed:0.78 green:0.87 blue:0.95 alpha:1.0];
    _nightBackgroundColor = [UIColor colorWithRed:0.20 green:0.25 blue:0.35 alpha:1.0];
}

- (void)_setupViews {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    
    _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    _backgroundView.backgroundColor = _dayBackgroundColor;
    _backgroundView.layer.cornerRadius = self.bounds.size.height / 2.0;
    _backgroundView.clipsToBounds = YES;
    _backgroundView.userInteractionEnabled = NO;
    [self addSubview:_backgroundView];
    
    _animView = [[UIImageView alloc] initWithFrame:self.bounds];
    _animView.contentMode = UIViewContentModeScaleAspectFill;
    _animView.clipsToBounds = YES;
    _animView.userInteractionEnabled = NO;
    _animView.layer.cornerRadius = self.bounds.size.height / 2.0;
    [self addSubview:_animView];
    
    [self addTarget:self action:@selector(_onTap) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - 加载 PNG 序列

- (void)_loadFrames {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSMutableArray *d2n = [NSMutableArray arrayWithCapacity:24];
    NSMutableArray *n2d = [NSMutableArray arrayWithCapacity:24];
    
    for (int i = 0; i < 24; i++) {
        NSString *name = [NSString stringWithFormat:@"replay%d", i];
        UIImage *img = [UIImage imageNamed:name 
                                   inBundle:bundle 
              compatibleWithTraitCollection:nil];
        if (img) [d2n addObject:img];
    }
    
    for (int i = 24; i < 48; i++) {
        NSString *name = [NSString stringWithFormat:@"replay%d", i];
        UIImage *img = [UIImage imageNamed:name 
                                   inBundle:bundle 
              compatibleWithTraitCollection:nil];
        if (img) [n2d addObject:img];
    }
    
    _dayToNightFrames = [d2n copy];
    _nightToDayFrames = [n2d copy];
    
    NSLog(@"[FushengDayNightSwitch] loaded %lu + %lu frames", 
          (unsigned long)_dayToNightFrames.count, 
          (unsigned long)_nightToDayFrames.count);
}

#pragma mark - 状态切换

- (void)_onTap {
    if (_isAnimating) return;
    [self setOn:!_on animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on {
    [self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    if (_on == on && !animated) {
        _on = on;
        [self _refreshDisplay];
        return;
    }
    
    BOOL wasOn = _on;
    _on = on;
    
    if (!animated || wasOn == on) {
        [self _refreshDisplay];
        return;
    }
    
    [self _playTransition:on];
}

- (void)_refreshDisplay {
    if (_on) {
        _animView.image = [_dayToNightFrames lastObject];
        _backgroundView.backgroundColor = _nightBackgroundColor;
    } else {
        _animView.image = [_nightToDayFrames lastObject];
        _backgroundView.backgroundColor = _dayBackgroundColor;
    }
}

- (void)_playTransition:(BOOL)toOn {
    _isAnimating = YES;
    
    NSArray<UIImage *> *frames = toOn ? _dayToNightFrames : _nightToDayFrames;
    if (frames.count == 0) {
        _isAnimating = NO;
        [self _refreshDisplay];
        return;
    }
    
    NSTimeInterval duration = 0.6;
    
    _animView.animationImages = frames;
    _animView.animationDuration = duration;
    _animView.animationRepeatCount = 1;
    [_animView startAnimating];
    
    UIColor *targetColor = toOn ? _nightBackgroundColor : _dayBackgroundColor;
    [UIView animateWithDuration:duration animations:^{
        self->_backgroundView.backgroundColor = targetColor;
    }];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf->_animView stopAnimating];
        strongSelf->_animView.animationImages = nil;
        strongSelf->_animView.image = [frames lastObject];
        strongSelf->_isAnimating = NO;
    });
}

#pragma mark - 颜色 setter

- (void)setDayBackgroundColor:(UIColor *)color {
    _dayBackgroundColor = color ?: [UIColor colorWithRed:0.78 green:0.87 blue:0.95 alpha:1.0];
    if (!_on) _backgroundView.backgroundColor = _dayBackgroundColor;
}

- (void)setNightBackgroundColor:(UIColor *)color {
    _nightBackgroundColor = color ?: [UIColor colorWithRed:0.20 green:0.25 blue:0.35 alpha:1.0];
    if (_on) _backgroundView.backgroundColor = _nightBackgroundColor;
}

#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];
    _backgroundView.frame = self.bounds;
    _backgroundView.layer.cornerRadius = self.bounds.size.height / 2.0;
    _animView.frame = self.bounds;
    _animView.layer.cornerRadius = self.bounds.size.height / 2.0;
}

@end