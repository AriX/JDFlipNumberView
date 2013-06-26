//
//  JDFlipNumberDigitView.m
//
//  Created by Markus Emrich on 26.02.11.
//  Copyright 2011 Markus Emrich. All rights reserved.
//
//
//  based on
//  www.voyce.com/index.php/2010/04/10/creating-an-ipad-flip-clock-with-core-animation/
//

#import <QuartzCore/QuartzCore.h>
#import "JDFlipNumberViewImageFactory.h"

#import "JDFlipNumberDigitView.h"

static NSString* kFlipAnimationKey = @"kFlipAnimationKey";
static CGFloat kFlipAnimationMinimumAnimationDuration = 0.05;
static CGFloat kFlipAnimationMaximumAnimationDuration = 0.70;

typedef NS_OPTIONS(NSUInteger, JDFlipAnimationState) {
	JDFlipAnimationStateFirstHalf,
	JDFlipAnimationStateSecondHalf
};


@interface JDFlipNumberDigitView ()
@property (nonatomic, assign) JDImageView *topImageView;
@property (nonatomic, assign) JDImageView *flipImageView;
@property (nonatomic, assign) JDImageView *bottomImageView;
@property (nonatomic, assign) JDFlipAnimationState animationState;
@property (nonatomic, assign) JDFlipAnimationType animationType;
@property (nonatomic, assign) NSUInteger previousValue;
@property (nonatomic, copy) JDDigitAnimationCompletionBlock completionBlock;
- (void)commonInit;
- (void)initImagesAndFrames;
- (void)updateFlipViewFrame;
- (void)updateImagesAnimated:(BOOL)animated;
- (void)runAnimation;
@end


@implementation JDFlipNumberDigitView

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    [_completionBlock release];
    
    [super dealloc];
}

- (void)awakeFromNib;
{
    [self commonInit];
}

- (void)commonInit;
{
    // setup view
#if TARGET_OS_IPHONE
    self.backgroundColor = [UIColor clearColor];
#endif
    self.autoresizesSubviews = NO;
    self.autoresizingMask = JDViewAutoresizingFlexibleTopMargin | JDViewAutoresizingFlexibleLeftMargin | JDViewAutoresizingFlexibleBottomMargin | JDViewAutoresizingFlexibleRightMargin;
    
    // default values
    _value = 0;
    _animationState = JDFlipAnimationStateFirstHalf;
    _animationDuration = kFlipAnimationMaximumAnimationDuration;
    
    // images & frame
    [self initImagesAndFrames];
}

- (void)initImagesAndFrames;
{
    // setup image views
    JDImageView *topImageView = [[JDImageView alloc] init];
    JDImageView *flipImageView = [[JDImageView alloc] init];
    JDImageView *bottomImageView = [[JDImageView alloc] init];

#if !TARGET_OS_IPHONE
    self.wantsLayer = YES;
    topImageView.wantsLayer = YES;
    flipImageView.wantsLayer = YES;
	bottomImageView.wantsLayer = YES;
#endif
    
    topImageView.image = JD_IMG_FACTORY.topImages[0];
    flipImageView.image = JD_IMG_FACTORY.topImages[0];
    bottomImageView.image = JD_IMG_FACTORY.bottomImages[0];
    
    flipImageView.hidden = YES;
	
	bottomImageView.frame = CGRectMake(0, JD_IMG_FACTORY.imageSize.height,
                                            JD_IMG_FACTORY.imageSize.width,
                                            JD_IMG_FACTORY.imageSize.height);
	
	// add image views
	[self addSubview:topImageView];
	[self addSubview:bottomImageView];
	[self addSubview:flipImageView];
    
    self.topImageView = topImageView;
	self.flipImageView = flipImageView;
	self.bottomImageView = bottomImageView;
    
    [topImageView release];
    [flipImageView release];
    [bottomImageView release];
	
	// setup default 3d transform
	[self setZDistance: (JD_IMG_FACTORY.imageSize.height*2)*3];
    
    // setup frame
    super.frame = CGRectMake(0, 0, JD_IMG_FACTORY.imageSize.width, JD_IMG_FACTORY.imageSize.height*2);
}

- (CGSize)sizeThatFits:(CGSize)aSize;
{
    CGSize imageSize = JD_IMG_FACTORY.imageSize;
    
    CGFloat ratioW     = aSize.width/aSize.height;
    CGFloat origRatioW = imageSize.width/(imageSize.height*2);
    CGFloat origRatioH = (imageSize.height*2)/imageSize.width;
    
    if (ratioW>origRatioW) {
        aSize.width = aSize.height*origRatioW;
    } else {
        aSize.height = aSize.width*origRatioH;
    }
    
    return aSize;
}


#pragma mark -
#pragma mark external access

- (void)setFrame:(CGRect)rect;
{
    [self setFrame:rect allowUpscaling:NO];
}

- (void)setFrame:(CGRect)rect allowUpscaling:(BOOL)upscalingAllowed;
{
    if (!upscalingAllowed) {
        rect.size.width  = MIN(rect.size.width, JD_IMG_FACTORY.imageSize.width);
        rect.size.height = MIN(rect.size.height, JD_IMG_FACTORY.imageSize.height*2);
    }
    
    rect.size = [self sizeThatFits: rect.size];
	[super setFrame: rect];
    
    // update imageView frames
    rect.origin = CGPointMake(0, 0);
    rect.size.height /= 2.0;
#if TARGET_OS_IPHONE
    self.topImageView.frame = rect;
#else
    self.bottomImageView.frame = rect;
#endif
    rect.origin.y += rect.size.height;
#if TARGET_OS_IPHONE
    self.bottomImageView.frame = rect;
#else
    self.topImageView.frame = rect;
#endif

    // update flip imageView frame
    BOOL isFirstHalf = (self.animationState == JDFlipAnimationStateFirstHalf);
    self.flipImageView.frame = (isFirstHalf) ? self.topImageView.frame : self.bottomImageView.frame;
	
    // reset Z distance
	[self setZDistance: self.frame.size.height*3];
}

- (void)setZDistance:(NSUInteger)zDistance;
{
	// setup 3d transform
	CATransform3D aTransform = CATransform3DIdentity;
	aTransform.m34 = -1.0 / zDistance;	
	self.layer.sublayerTransform = aTransform;
}

- (void)setValue:(NSUInteger)value
{
    [self setValue:value withAnimationType:JDFlipAnimationTypeNone completion:nil];
}

- (void)setValue:(NSUInteger)value withAnimationType:(JDFlipAnimationType)animationType
      completion:(JDDigitAnimationCompletionBlock)completionBlock;
{
    // copy completion block
    self.completionBlock = completionBlock;
    
	// save previous value
    self.previousValue = self.value;
	NSInteger newValue = value % 10;

    // update animation type
    self.animationType = animationType;
	BOOL animated = (animationType != JDFlipAnimationTypeNone);
    
    // save new value
    _value = newValue;
	
    [self updateImagesAnimated:animated];
}

#pragma mark -
#pragma mark animation

- (void)updateImagesAnimated:(BOOL)animated
{
    if (!animated || self.animationDuration < kFlipAnimationMinimumAnimationDuration) {
        // show new value
        self.topImageView.image	   = JD_IMG_FACTORY.topImages[self.value];
        self.flipImageView.image   = JD_IMG_FACTORY.topImages[self.value];
        self.bottomImageView.image = JD_IMG_FACTORY.bottomImages[self.value];
        
        // reset state
        self.flipImageView.hidden = YES;
        
        // call completion immediatly
        if (self.completionBlock) {
            self.completionBlock(YES);
            self.completionBlock = nil;
        }
    } else {
        self.animationState = JDFlipAnimationStateFirstHalf;
        [self runAnimation];
    }
}

- (void)runAnimation;
{
	[self updateFlipViewFrame];
    
    BOOL isTopDown = self.animationType == JDFlipAnimationTypeTopDown;
	
	// setup animation
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
	animation.duration	= MIN(kFlipAnimationMaximumAnimationDuration/2.0,self.animationDuration/2.0);
	animation.delegate	= self;
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeForwards;
    
	// exchange images & setup animation
	if (self.animationState == JDFlipAnimationStateFirstHalf) {
        // remove any old animations
        [self.flipImageView.layer removeAllAnimations];
        
		// setup first animation half
        self.topImageView.image	   = JD_IMG_FACTORY.topImages[isTopDown ? self.value : self.previousValue];
        self.flipImageView.image   = isTopDown ? JD_IMG_FACTORY.topImages[self.previousValue] : JD_IMG_FACTORY.bottomImages[self.previousValue];
        self.bottomImageView.image = JD_IMG_FACTORY.bottomImages[isTopDown ? self.previousValue : self.value];
		
#if TARGET_OS_IPHONE
        CGFloat angle = (isTopDown ?- M_PI_2 : M_PI_2);
#else
        CGFloat angle = (!isTopDown ? -M_PI_2 : M_PI_2);
#endif
        animation.fromValue	= [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 1, 0, 0)];
        animation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(angle, 1, 0, 0)];
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	} else {
		// setup second animation half
        if (isTopDown) {
            self.flipImageView.image = JD_IMG_FACTORY.bottomImages[self.value];
        } else {
            self.flipImageView.image = JD_IMG_FACTORY.topImages[self.value];
        }
        
#if TARGET_OS_IPHONE
        CGFloat angle = (isTopDown ? M_PI_2 : -M_PI_2);
#else
        CGFloat angle = (!isTopDown ? M_PI_2 : -M_PI_2);
#endif
		animation.fromValue	= [NSValue valueWithCATransform3D:CATransform3DMakeRotation(angle, 1, 0, 0)];
		animation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 1, 0, 0)];
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	}
	
	// add/start animation
	[self.flipImageView.layer addAnimation: animation forKey: kFlipAnimationKey];
    
	// show animated view
	self.flipImageView.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished
{
	if (!finished) {
        if (self.completionBlock) {
            self.completionBlock(NO);
            self.completionBlock = nil;
        }
		return;
	}
	
	if (self.animationState == JDFlipAnimationStateFirstHalf) {
		// do second animation step
		self.animationState = JDFlipAnimationStateSecondHalf;
		[self runAnimation];
	} else {
		// reset state
		self.animationState = JDFlipAnimationStateFirstHalf;
		
		// update images
        if(self.animationType == JDFlipAnimationTypeTopDown) {
            self.bottomImageView.image = JD_IMG_FACTORY.bottomImages[self.value];
        } else {
            self.topImageView.image = JD_IMG_FACTORY.topImages[self.value];
        }
        self.flipImageView.hidden  = YES;
		
		// remove old animation
		[self.flipImageView.layer removeAnimationForKey: kFlipAnimationKey];
        
        // call completion block
        if (self.completionBlock) {
            self.completionBlock(YES);
            self.completionBlock = nil;
        }
	}
}

- (void)updateFlipViewFrame;
{
    if ((self.animationType == JDFlipAnimationTypeTopDown && self.animationState == JDFlipAnimationStateFirstHalf) ||
        (self.animationType == JDFlipAnimationTypeBottomUp && self.animationState == JDFlipAnimationStateSecondHalf)) {
#if TARGET_OS_IPHONE
        self.flipImageView.layer.anchorPoint = CGPointMake(0.5, 1.0);
#else
        self.flipImageView.layer.anchorPoint = CGPointMake(0.0, 0.0);
#endif
		self.flipImageView.frame = self.topImageView.frame;
	} else {
#if TARGET_OS_IPHONE
        self.flipImageView.layer.anchorPoint = CGPointMake(0.5, 0.0);
		self.flipImageView.frame = self.bottomImageView.frame;
#else
        self.flipImageView.layer.anchorPoint = CGPointMake(0.0, 1.0);
		self.flipImageView.frame = self.topImageView.frame;
#endif
	}
}

@end
