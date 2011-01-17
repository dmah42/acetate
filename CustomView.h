//
//  CustomView.h
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CustomView : NSView {
	NSImage* canvas;
	NSBezierPath* path;
	NSColor* brushColor;
	BOOL shouldDrawPath;
}

- (void)setBrushColor:(NSColor *) color;

@end
