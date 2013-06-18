//
//  JDCompatibility.h
//  DeskConnect
//
//  Created by Ari on 6/18/13.
//  Copyright (c) 2013 Squish Software. All rights reserved.
//

#pragma mark - Mac/iOS class compatibility aliases

#if TARGET_OS_IPHONE
@compatibility_alias JDImage UIImage;
@compatibility_alias JDImageView UIImageView;
@compatibility_alias JDView UIView;
#else
@compatibility_alias JDImage NSImage;
@compatibility_alias JDImageView NSImageView;
@compatibility_alias JDView NSView;
#endif

#pragma mark - Autoresizing mask compatibility

#if TARGET_OS_IPHONE

enum {
    JDViewAutoresizingNone = UIViewAutoresizingNone,
    JDViewAutoresizingFlexibleLeftMargin = UIViewAutoresizingFlexibleLeftMargin,
    JDViewAutoresizingFlexibleWidth = UIViewAutoresizingFlexibleWidth,
    JDViewAutoresizingFlexibleRightMargin = UIViewAutoresizingFlexibleRightMargin,
    JDViewAutoresizingFlexibleTopMargin = UIViewAutoresizingFlexibleTopMargin,
    JDViewAutoresizingFlexibleHeight = UIViewAutoresizingFlexibleHeight,
    JDViewAutoresizingFlexibleBottomMargin = UIViewAutoresizingFlexibleBottomMargin
};

#else

enum {
    JDViewAutoresizingNone = NSViewNotSizable,
    JDViewAutoresizingFlexibleLeftMargin = NSViewMinXMargin,
    JDViewAutoresizingFlexibleWidth = NSViewWidthSizable,
    JDViewAutoresizingFlexibleRightMargin = NSViewMaxXMargin,
    JDViewAutoresizingFlexibleTopMargin = NSViewMaxYMargin,
    JDViewAutoresizingFlexibleHeight = NSViewHeightSizable,
    JDViewAutoresizingFlexibleBottomMargin = NSViewMinYMargin
};

#endif