//
//  JDFlipNumberViewImageFactory.m
//  FlipNumberViewExample
//
//  Created by Markus Emrich on 05.12.12.
//  Copyright (c) 2012 markusemrich. All rights reserved.
//

#import "JDFlipNumberViewImageFactory.h"
#import "JDCompatibility.h"

static JDFlipNumberViewImageFactory *sharedInstance;

@interface JDFlipNumberViewImageFactory ()
@property (nonatomic, retain) NSArray *topImages;
@property (nonatomic, retain) NSArray *bottomImages;
@property (nonatomic, retain) NSString *imagePrefix;
- (void)setup;
@end

@implementation JDFlipNumberViewImageFactory

+ (JDFlipNumberViewImageFactory*)sharedInstance;
{
    if (sharedInstance != nil) {
        return sharedInstance;
    }
    
    return [[self alloc] init];
}

- (id)init
{
    @synchronized(self)
    {
        if (sharedInstance != nil) {
            return sharedInstance;
        }
        
        self = [super init];
        if (self) {
            sharedInstance = self;
            self.imagePrefix = @"JDFlipNumberView";
            [self setup];
        }
        return self;
    }
}

- (void)dealloc {
    [_topImages release];
    [_bottomImages release];
    [_imagePrefix release];

#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif

    [super dealloc];
}

- (void)setup;
{
    // create default images
    [self generateImagesWithPrefix:self.imagePrefix];
    
#if TARGET_OS_IPHONE
    // register for memory warnings
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
#endif
}

+ (id)allocWithZone:(NSZone *)zone;
{
    if (sharedInstance != nil) {
        return sharedInstance;
    }
    return [super allocWithZone:zone];
}

#pragma mark -
#pragma mark getter

- (NSArray *)topImages;
{
    @synchronized(self)
    {
        if (_topImages.count == 0) {
            [self generateImagesWithPrefix:self.imagePrefix];
        }
        
        return _topImages;
    }
}

- (NSArray *)bottomImages;
{
    @synchronized(self)
    {
        if (_bottomImages.count == 0) {
            [self generateImagesWithPrefix:self.imagePrefix];
        }
        
        return _bottomImages;
    }
}

- (CGSize)imageSize
{
    return ((JDImage*)self.topImages[0]).size;
}

#pragma mark -
#pragma mark image generation
- (void)generateImagesWithPrefix:(NSString*)prefix;
{
    self.imagePrefix = prefix;
    // create image array
	NSMutableArray* topImages = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray* bottomImages = [NSMutableArray arrayWithCapacity:10];
	
	// create bottom and top images
    for (NSInteger j=0; j<10; j++) {
        for (int i=0; i<2; i++) {
            NSString *imageName = [NSString stringWithFormat: @"%@%ld", prefix, (long)j];
			JDImage *sourceImage = [JDImage imageNamed:imageName];
			CGSize size		= CGSizeMake(sourceImage.size.width, sourceImage.size.height/2);
			
            NSAssert(sourceImage != nil, @"Did not find image %@", imageName);
            
            // draw half of image and create new image
#if TARGET_OS_IPHONE
            CGFloat yPoint	= (i==0) ? 0 : -size.height;
			UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
			[sourceImage drawAtPoint:CGPointMake(0,yPoint)];
			UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
#else
            CGFloat yPoint	= (i!=0) ? 0 : -size.height;
            NSImage *image = [[NSImage alloc] initWithSize:size];
            [image lockFocus];
            [sourceImage drawAtPoint:CGPointMake(0,yPoint) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            [image unlockFocus];
            [image autorelease];
#endif
            
            // save image
            if (i==0) {
                [topImages addObject:image];
            } else {
                [bottomImages addObject:image];
            }
		}
	}
	
    // save images
	self.topImages    = [NSArray arrayWithArray:topImages];
	self.bottomImages = [NSArray arrayWithArray:bottomImages];
}

#pragma mark -
#pragma mark memory

// clear memory
- (void)didReceiveMemoryWarning:(NSNotification*)notification;
{
    self.topImages = @[];
    self.bottomImages = @[];
}

@end
