//
//  CustomView.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//


#import "CustomView.h"
#import <AppKit/AppKit.h>

#define ERASER_WIDTH	8.0
#define LINE_WIDTH		4.0
#define POINT_SIZE		8.0

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
	drawCanvas = [[NSImage alloc] initWithSize:canvasSize];
	eraseCanvas = [[NSImage alloc] initWithSize:canvasSize];
	resultCanvas = [[NSImage alloc] initWithSize:canvasSize];

	NSAssert(drawCanvas != nil, @"Failed to initialize canvas");
	NSAssert(eraseCanvas != nil, @"Failed to initialize canvas");
	NSAssert(resultCanvas != nil, @"Failed");
		
	shouldDrawPath = NO;
	brushColor = [[NSColor yellowColor] retain];
	
	activeTool = TOOL_PENCIL;
}

- (void)dealloc {
	[brushColor release];
	[resultCanvas dealloc];
	[eraseCanvas dealloc];
	[drawCanvas dealloc];
    [super dealloc];
}

- (void)setBrushColor:(NSColor *)color {
	[brushColor release];
	
	NSLog(@"Changing color to %.2f %.2f %.2f",
		  [color redComponent], [color greenComponent], [color blueComponent]);
	
	brushColor = [color retain];
}

- (void)setActiveTool:(Tool) tool {
	// TODO: when switching to drawing tool from erase tool, we need to copy the result
	// into the drawing and clear the erase canvas
	
	if (activeTool == TOOL_ERASER && tool != TOOL_ERASER) {
		// copy image contents
		[drawCanvas lockFocus];
		[resultCanvas compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
		[drawCanvas unlockFocus];
		
		// reinit erase canvas
		[eraseCanvas dealloc];
		
		NSRect viewRect = [self bounds];
		NSSize canvasSize = viewRect.size;
		eraseCanvas = [[NSImage alloc] initWithSize:canvasSize];

		[self setNeedsDisplay:YES];
	}
	
	activeTool = tool;
}

// drawing events
- (void)mouseDown:(NSEvent *)theEvent {    
	NSPoint loc = [self convertMousePointToViewLocation:[theEvent locationInWindow]];
    
	switch (activeTool) {
		case TOOL_PENCIL:
		case TOOL_ERASER:
			path = [[NSBezierPath bezierPath] retain];
	
			if (activeTool == TOOL_PENCIL)
				[path setLineWidth:LINE_WIDTH];
			else if (activeTool == TOOL_ERASER)
				[path setLineWidth:ERASER_WIDTH];
				
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
		case TOOL_ERASER:
			[path lineToPoint:loc];
			shouldDrawPath = YES;
			[self setNeedsDisplay:YES];
			break;
			
		case TOOL_POINT:
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
	NSImage* newDrawCanvas = [[NSImage alloc] initWithSize:canvasSize];	
	NSImage* newEraseCanvas = [[NSImage alloc] initWithSize:canvasSize];	
	
	// copy image contents
	[newDrawCanvas lockFocus];

	// TODO: fix the offset here
	// copy the old canvas to the new one
	[drawCanvas compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	[newDrawCanvas unlockFocus];
	
	[drawCanvas dealloc];
	drawCanvas = newDrawCanvas;
	
	// copy image contents
	[newEraseCanvas lockFocus];
	
	// copy the old canvas to the new one
	[eraseCanvas compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	[newEraseCanvas unlockFocus];
	
	[eraseCanvas dealloc];
	eraseCanvas = newEraseCanvas;
	
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
		NSColor* bgColor = [NSColor whiteColor];
		bgColor = [bgColor colorWithAlphaComponent:0.1];
		[bgColor set];
	
		NSRectFill([self frame]);
	
		// draw the path to the canvas
		if (shouldDrawPath) {
			switch (activeTool) {
				case TOOL_ERASER: {
					[eraseCanvas lockFocus];
					
					// draw in opaque and composite to make transparent
					NSColor* eraseColor = [NSColor whiteColor];
					[eraseColor set];
					[path stroke];

					[eraseCanvas unlockFocus];
				}	break;
					
				case TOOL_PENCIL:
					[drawCanvas lockFocus];
					[brushColor set];
					[path stroke];
					[drawCanvas unlockFocus];
					break;
					
				case TOOL_POINT:
					[drawCanvas lockFocus];
					[[NSColor blackColor] set];
					[path stroke];
					
					[brushColor set];
					[path fill];
					[drawCanvas unlockFocus];
					break;
			}
		}
		
		// draw the canvases to the result canvas	
		[resultCanvas lockFocus];

		[drawCanvas compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
		[eraseCanvas compositeToPoint:NSZeroPoint operation:NSCompositeDestinationOut];

		[resultCanvas unlockFocus];
		
		// and write the result canvas to the view
		[resultCanvas compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	}
}

@end
