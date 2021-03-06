//
//  JDCountdownFlipView.m
//
//  Created by Markus Emrich on 12.03.11.
//  Copyright 2011 Markus Emrich. All rights reserved.
//

#import "JDDateCountdownFlipView.h"

static CGFloat kFlipAnimationUpdateInterval = 0.5; // = 2 times per second

@interface JDDateCountdownFlipView ()
@property (nonatomic) NSInteger dayDigitCount;
@property (nonatomic, assign) JDFlipNumberView* dayFlipNumberView;
@property (nonatomic, assign) JDFlipNumberView* hourFlipNumberView;
@property (nonatomic, assign) JDFlipNumberView* minuteFlipNumberView;
@property (nonatomic, assign) JDFlipNumberView* secondFlipNumberView;

@property (nonatomic, retain) NSTimer *animationTimer;
- (void)setupUpdateTimer;
- (void)handleTimer:(NSTimer*)timer;
@end

@implementation JDDateCountdownFlipView

- (id)init
{
    return [self initWithDayDigitCount:3];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithDayDigitCount:3];
    if (self) {
        self.frame = frame;
    }
    return self;
}

- (id)initWithDayDigitCount:(NSInteger)dayDigits;
{
    self = [super initWithFrame: CGRectZero];
    if (self) {
        _dayDigitCount = dayDigits;
        // view setup
#if TARGET_OS_IPHONE
        self.backgroundColor = [UIColor clearColor];
#endif
        self.autoresizesSubviews = NO;
        self.autoresizingMask = JDViewAutoresizingFlexibleTopMargin | JDViewAutoresizingFlexibleLeftMargin | JDViewAutoresizingFlexibleBottomMargin | JDViewAutoresizingFlexibleRightMargin;
		
        // setup flipviews
        JDFlipNumberView *dayFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:_dayDigitCount];
        JDFlipNumberView *hourFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:2];
        JDFlipNumberView *minuteFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:2];
        JDFlipNumberView *secondFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:2];
        
        hourFlipNumberView.maximumValue = 23;
        minuteFlipNumberView.maximumValue = 59;
        secondFlipNumberView.maximumValue = 59;

        [self setZDistance: 60];
        
        // set inital frame
        CGRect frame = hourFlipNumberView.frame;
        self.frame = CGRectMake(0, 0, frame.size.width*(dayDigits+7), frame.size.height);
        
        // add subviews
        [self addSubview:dayFlipNumberView];
        [self addSubview:hourFlipNumberView];
        [self addSubview:minuteFlipNumberView];
        [self addSubview:secondFlipNumberView];
        
        self.dayFlipNumberView = dayFlipNumberView;
        self.hourFlipNumberView = hourFlipNumberView;
        self.minuteFlipNumberView = minuteFlipNumberView;
        self.secondFlipNumberView = secondFlipNumberView;
        
        [dayFlipNumberView release];
        [hourFlipNumberView release];
        [minuteFlipNumberView release];
        [secondFlipNumberView release];
        
        // set inital dates
        self.targetDate = [NSDate date];
        [self setupUpdateTimer];
    }
    return self;
}

- (void)dealloc {
    [_targetDate release];
    [_animationTimer release];
    
    [super dealloc];
}

#pragma mark setter

- (void)setZDistance:(NSUInteger)zDistance;
{
    for (JDFlipNumberView* view in @[self.dayFlipNumberView, self.hourFlipNumberView, self.minuteFlipNumberView, self.secondFlipNumberView]) {
        [view setZDistance:zDistance];
    }
}

- (void)setFrame:(CGRect)frame;
{
    if (self.dayFlipNumberView == nil) {
        [super setFrame:frame];
        return;
    }
    
    CGFloat digitWidth = frame.size.width/(self.dayFlipNumberView.digitCount+7);
    CGFloat margin     = digitWidth/3.0;
    CGFloat currentX   = 0;

    // resize first flipview
    self.dayFlipNumberView.frame = CGRectMake(0, 0, digitWidth * self.dayDigitCount, frame.size.height);
    currentX += self.dayFlipNumberView.frame.size.width;
    
    // update flipview frames
    for (JDFlipNumberView* view in @[self.hourFlipNumberView, self.minuteFlipNumberView, self.secondFlipNumberView]) {
        currentX   += margin;
        view.frame = CGRectMake(currentX, 0, digitWidth*2, frame.size.height);
        currentX   += view.frame.size.width;
    }
    
    // take bottom right of last view for new size, to match size of subviews
    CGRect lastFrame = self.secondFlipNumberView.frame;
    frame.size.width  = ceil(lastFrame.size.width  + lastFrame.origin.x);
    frame.size.height = ceil(lastFrame.size.height + lastFrame.origin.y);
    
    [super setFrame:frame];
}

- (void)setTargetDate:(NSDate *)targetDate;
{
    _targetDate = targetDate;
    [self updateValuesAnimated:NO];
}

#pragma mark update timer


- (void)start;
{
    if (self.animationTimer == nil) {
        [self setupUpdateTimer];
    }
}

- (void)stop;
{
    [self.animationTimer invalidate];
    self.animationTimer = nil;
}

- (void)setupUpdateTimer;
{
    self.animationTimer = [NSTimer timerWithTimeInterval:kFlipAnimationUpdateInterval
                                                  target:self
                                                selector:@selector(handleTimer:)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
}

- (void)handleTimer:(NSTimer*)timer;
{
    [self updateValuesAnimated:YES];
}

- (void)updateValuesAnimated:(BOOL)animated;
{
    if (self.targetDate == nil) {
        return;
    }
    
    if ([self.targetDate timeIntervalSinceDate:[NSDate date]] > 0) {
        NSUInteger flags = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:flags fromDate:[NSDate date] toDate:self.targetDate options:0];
        
        [self.dayFlipNumberView setValue:[dateComponents day] animated:animated];
        [self.hourFlipNumberView setValue:[dateComponents hour] animated:animated];
        [self.minuteFlipNumberView setValue:[dateComponents minute] animated:animated];
        [self.secondFlipNumberView setValue:[dateComponents second] animated:animated];
    } else {
        [self.dayFlipNumberView setValue:0 animated:animated];
        [self.hourFlipNumberView setValue:0 animated:animated];
        [self.minuteFlipNumberView setValue:0 animated:animated];
        [self.secondFlipNumberView setValue:0 animated:animated];
        [self stop];
    }
}

@end
