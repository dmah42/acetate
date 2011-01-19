//
//  CustomView.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//


#import "CustomView.h"
#import <AppKit/AppKit.h>

@implementation CustomView

- (void)awakeFromNib {
	NSRect viewRect = [self bounds];
	NSSize canvasSize = viewRect.size;
	canvas = [[NSImage alloc] initWithSize:canvasSize];
	
	NSAssert(canvas != nil, @"Failed to initialize canvas");
	
	shouldDrawPath = NO;
	brushColor = [[NSColor yellowColor] retain];
}

- (void)dealloc {
	[brushColor release];
	[canvas dealloc];
    [super dealloc];
}

- (void)setBrushColor:(NSColor *)color {
	[brushColor release];
	
	NSLog(@"Changing color to %.2f %.2f %.2f",
		  [color redComponent], [color greenComponent], [color blueComponent]);
	
	brushColor = [color retain];
}

// drawing events
- (void)mouseDown:(NSEvent *)theEvent {    
    NSPoint loc = [theEvent locationInWindow];
    loc.x -= [self frame].origin.x;
    loc.y -= [self frame].origin.y;
    
    path = [[NSBezierPath bezierPath] retain];
	
	[path setLineWidth:4.0];
    [path moveToPoint:loc];
	shouldDrawPath = YES;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint loc = [theEvent locationInWindow];
    loc.x -= [self frame].origin.x;
    loc.y -= [self frame].origin.y;
    
    [path lineToPoint:loc];
	shouldDrawPath = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[path release];
	shouldDrawPath = NO;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)viewDidEndLiveResize {
	NSRect viewRect = [self bounds];
	NSSize canvasSize = viewRect.size;
	NSImage* newCanvas = [[NSImage alloc] initWithSize:canvasSize];	
	
	// copy image contents
	[newCanvas lockFocus];

	// draw the old canvas to the new one
	[canvas drawAtPoint:NSMakePoint(0,0) 
			   fromRect:NSMakeRect(0, 0, canvas.size.width, canvas.size.height)
			  operation:NSCompositeCopy
			   fraction:1.0];
	
	[newCanvas unlockFocus];
	
	[canvas dealloc];
	canvas = newCanvas;
	
	shouldDrawPath = NO;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
	if ([self inLiveResize]) {
		// Clear the drawing rect to mostly opaque
		NSColor* color = [NSColor whiteColor];
		color = [color colorWithAlphaComponent:0.6];
		[color set];
		NSRectFill([self frame]);
	} else {
		// transparent fill
		NSColor* color = [NSColor whiteColor];
		color = [color colorWithAlphaComponent:0.1];
		[color set];
	
		NSRectFill([self frame]);
	
		// draw the path to the canvas
		if (shouldDrawPath) {
			[canvas lockFocus];
			[brushColor set];
			[path stroke];	
			[canvas unlockFocus];
		}
	
		// draw the canvas to the view
		[canvas drawAtPoint:NSMakePoint(0,0) 
				   fromRect:[self frame] 
				  operation:NSCompositeSourceOver 
				   fraction:1.0];
	}
}

@end
