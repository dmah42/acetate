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

- (NSPoint) convertMousePointToViewLocation:(NSPoint) pt {
	NSPoint loc = pt;
    loc.x -= [self frame].origin.x;
    loc.y -= [self frame].origin.y;	
	return loc;
}

- (void)awakeFromNib {
	[self clear];
	
	brushColor = [[NSColor yellowColor] retain];
	
	activeTool = TOOL_PENCIL;
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.bgAlpha"
																 options:0
																 context:nil];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.resizeAlpha"
																 options:0
																 context:nil];
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
	brushColor = [color retain];
}

- (void)setActiveTool:(Tool) tool {
	if (activeTool == TOOL_ERASER && tool != TOOL_ERASER) {
		// copy image contents
		[drawCanvas lockFocus];
		[resultCanvas drawAtPoint:NSZeroPoint 
						 fromRect:NSZeroRect
						operation:NSCompositeCopy 
						 fraction:1.0];
		[drawCanvas unlockFocus];
		[drawCanvas recache];
		
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
	
			if (activeTool == TOOL_PENCIL) {
				float pencilWidth = [[NSUserDefaults standardUserDefaults] floatForKey:@"pencilWidth"];

				[path setLineWidth:pencilWidth];
			} else if (activeTool == TOOL_ERASER) {
				float eraserWidth = [[NSUserDefaults standardUserDefaults] floatForKey:@"eraserWidth"];

				[path setLineWidth:eraserWidth];
			}
			
			[path moveToPoint:loc];
			shouldDrawPath = YES;
			break;
			
		case TOOL_POINT: {
			float pointSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"pointSize"];

			const float halfPointSize = pointSize / 2;
			NSRect ovalRect = NSMakeRect(loc.x - halfPointSize, loc.y - halfPointSize,
										 pointSize, pointSize);
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
	if (path) {
		[path release];
	}
	shouldDrawPath = NO;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)onResize {
	if (![self inLiveResize]) {
		NSRect viewRect = [self bounds];
		NSSize canvasSize = viewRect.size;
		[drawCanvas dealloc];
		drawCanvas = [[NSImage alloc] initWithSize:canvasSize];	
		
		// copy image contents
		[drawCanvas lockFocus];
		
		// copy the old canvas to the new one
		[resultCanvas drawAtPoint:NSMakePoint(0,canvasSize.height - resultCanvas.size.height)
						 fromRect:NSZeroRect
						operation:NSCompositeCopy 
						 fraction:1.0];
		[drawCanvas unlockFocus];
		[drawCanvas recache];
		
		// reinit erase and result canvas
		[eraseCanvas dealloc];
		eraseCanvas = [[NSImage alloc] initWithSize:canvasSize];
		
		[resultCanvas dealloc];
		resultCanvas = [[NSImage alloc] initWithSize:canvasSize];
		
		shouldDrawPath = NO;
		[self setNeedsDisplay:YES];		
	}
}

- (void)viewDidEndLiveResize {
	[self onResize];
}

- (void)drawRect:(NSRect)rect {
	if ([self inLiveResize]) {
		// Clear the drawing rect to mostly opaque
		NSColor* color = [NSColor whiteColor];

		float resizeAlpha = [[NSUserDefaults standardUserDefaults] floatForKey:@"resizeAlpha"];

		color = [color colorWithAlphaComponent:resizeAlpha];
		[color set];
		NSRectFill([self frame]);
		
		[self.window setDocumentEdited:YES];
	} else {
		// transparent fill
		NSColor* bgColor = [NSColor whiteColor];
		
		float bgAlpha = [[NSUserDefaults standardUserDefaults] floatForKey:@"bgAlpha"];
		
		bgColor = [bgColor colorWithAlphaComponent:bgAlpha];
		[bgColor set];
	
		NSRectFill([self frame]);
	
		// draw the path to the canvas
		if (shouldDrawPath) {
			
			[self.window setDocumentEdited:YES];
			
			switch (activeTool) {
				case TOOL_ERASER: {
					[eraseCanvas lockFocus];
					
					// draw in opaque and composite to make transparent
					NSColor* eraseColor = [NSColor whiteColor];
					[eraseColor set];
					[path stroke];

					[eraseCanvas unlockFocus];
					[eraseCanvas recache];
				}	break;
					
				case TOOL_PENCIL:
					[drawCanvas lockFocus];
					[brushColor set];
					[path stroke];
					[drawCanvas unlockFocus];
					[drawCanvas recache];
					break;
					
				case TOOL_POINT:
					[drawCanvas lockFocus];
					[[NSColor blackColor] set];
					[path stroke];
					
					[brushColor set];
					[path fill];
					[drawCanvas unlockFocus];
					[drawCanvas recache];
					break;
			}
		}
		
		// draw the canvases to the result canvas	
		[resultCanvas lockFocus];

		[drawCanvas compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
		[eraseCanvas compositeToPoint:NSZeroPoint operation:NSCompositeDestinationOut];

		[resultCanvas unlockFocus];
		[resultCanvas recache];
		
		// and write the result canvas to the view
		[resultCanvas compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	}
}

// user default change
- (void) observeValueForKeyPath:(NSString *)keyPath
					   ofObject:(id)object
						 change:(NSDictionary *)change
                        context:(void *)context
{
    if (([keyPath isEqualToString:@"values.bgAlpha"]) ||
		([keyPath isEqualToString:@"values.resizeAlpha"]) ) {
		[self setNeedsDisplay:YES];
	}
}

- (void) clear {
	NSRect viewRect = [self bounds];
	NSSize canvasSize = viewRect.size;

	if (drawCanvas)
		[drawCanvas dealloc];
	drawCanvas = [[NSImage alloc] initWithSize:canvasSize];
	
	if (eraseCanvas)
		[eraseCanvas dealloc];
	eraseCanvas = [[NSImage alloc] initWithSize:canvasSize];
	
	if (resultCanvas)
		[resultCanvas dealloc];
	resultCanvas = [[NSImage alloc] initWithSize:canvasSize];
	
	NSAssert(drawCanvas != nil, @"Failed to initialize canvas");
	NSAssert(eraseCanvas != nil, @"Failed to initialize canvas");
	NSAssert(resultCanvas != nil, @"Failed to initialize canvas");
	
	shouldDrawPath = NO;
	[self setNeedsDisplay:YES];
}

- (void)saveToFile:(NSString*)filepath {
	NSBitmapImageRep* bm = [NSBitmapImageRep imageRepWithData:[resultCanvas TIFFRepresentation]];
	NSData* dataRep = [bm representationUsingType:NSPNGFileType properties:nil];
	
	BOOL success = [dataRep writeToFile:filepath atomically:YES];
	NSAssert1(success, @"Failed to save to %@", filepath);
}

@end
