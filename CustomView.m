//
//  CustomView.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//


#import "CustomView.h"
#import <AppKit/AppKit.h>

#define LINE_WIDTH	4.0
#define POINT_SIZE	8.0

@implementation CustomView

- (NSPoint) convertMousePointToViewLocation:(NSPoint) pt {
	NSPoint loc = pt;
    loc.x -= [self frame].origin.x;
    loc.y -= [self frame].origin.y;	
	return loc;
}

- (void)awakeFromNib {
	NSRect viewRect = [self bounds];
	NSSize canvasSize = viewRect.size;
	canvas = [[NSImage alloc] initWithSize:canvasSize];
	
	NSAssert(canvas != nil, @"Failed to initialize canvas");
	
	shouldDrawPath = NO;
	brushColor = [[NSColor yellowColor] retain];
	
	activeTool = TOOL_PENCIL;
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

- (void)setActiveTool:(Tool) tool {
	activeTool = tool;
}

// drawing events
- (void)mouseDown:(NSEvent *)theEvent {    
	NSPoint loc = [self convertMousePointToViewLocation:[theEvent locationInWindow]];
    
	switch (activeTool) {
		case TOOL_PENCIL:
			path = [[NSBezierPath bezierPath] retain];
	
			[path setLineWidth:LINE_WIDTH];
			[path moveToPoint:loc];
			shouldDrawPath = YES;
			break;
			
		case TOOL_POINT: {
			const float halfPointSize = POINT_SIZE / 2;
			NSRect ovalRect = NSMakeRect(loc.x - halfPointSize, loc.y - halfPointSize,
										 POINT_SIZE, POINT_SIZE);
			path = [[NSBezierPath bezierPathWithOvalInRect:ovalRect] retain];
			shouldDrawPath = YES;
			[self setNeedsDisplay:YES];
		}	break;
	};
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint loc = [self convertMousePointToViewLocation:[theEvent locationInWindow]];
    
	switch (activeTool) {
		case TOOL_PENCIL:
			[path lineToPoint:loc];
			shouldDrawPath = YES;
			[self setNeedsDisplay:YES];
			break;
			
		case TOOL_POINT:
			// TODO: draw point on mouse up?
			shouldDrawPath = NO;
			break;
	}
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
			
			switch (activeTool) {
				case TOOL_PENCIL:
					[brushColor set];
					[path stroke];
					break;
					
				case TOOL_POINT:
					[[NSColor blackColor] set];
					[path stroke];
					
					[brushColor set];
					[path fill];
					break;
			}
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
