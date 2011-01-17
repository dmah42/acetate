//
//  MainWindow.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import "CustomView.h"
#import "MainWindow.h"
#import <AppKit/AppKit.h>

@implementation MainWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle
				                              backing:(NSBackingStoreType)bufferingType
					                          defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect
				  styleMask:(NSResizableWindowMask | NSClosableWindowMask)
				  backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {
		[self setAlphaValue:1.0];
        [self setOpaque:NO];
	}
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end
