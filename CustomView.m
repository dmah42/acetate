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
	[resultCanvas release];
	[eraseCanvas release];
	[drawCanvas release];
    [super dealloc];
}

- (void)createSnapshotOnUndoStack {
	NSRect viewRect = [self bounds];
	NSSize canvasSize = viewRect.size;

	NSImage* snapshot = [[NSImage alloc] initWithSize:canvasSize];
	DLOG(@"createSnapshot: %@", snapshot);
	NSAssert(snapshot != nil, @"Failed to initialize snapshot");

	// copy image contents
	[snapshot lockFocus];
	
	// copy the old canvas to the new one
	DLOG(@"Blitting resultCanvas %@ to snapshot %@", resultCanvas, snapshot);
	[resultCanvas drawAtPoint:NSZeroPoint
					 fromRect:NSZeroRect
					operation:NSCompositeCopy 
					 fraction:1.0];
	[snapshot unlockFocus];
	[snapshot recache];
	
	[[self undoManager] registerUndoWithTarget:self
									  selector:@selector(setDrawCanvas:)
										object:snapshot];
}

- (void)setBrushColor:(NSColor *)color {
	[brushColor release];
	brushColor = [color retain];
}

- (void)setDrawCanvas:(NSImage*) newImage {
	NSRect viewRect = [self bounds];
	NSSize canvasSize = viewRect.size;
	
	DLOG(@"setDrawCanvas: releasing drawCanvas: %@ %d", drawCanvas, [drawCanvas retainCount]);
	[drawCanvas release];
	drawCanvas = [[NSImage alloc] initWithSize:canvasSize];
	DLOG(@"setDrawCanvas: drawCanvas: %@", drawCanvas);
	NSAssert(drawCanvas != nil, @"Failed to initialize canvas");
	
	if (newImage != nil) {
		// copy image contents
		[drawCanvas lockFocus];
		
		// copy the old canvas to the new one
		NSPoint blitOrigin = NSMakePoint(0,canvasSize.height - newImage.size.height);
		DLOG(@"Blitting new image %@ to (%d, %d)", newImage, blitOrigin.x, blitOrigin.y);
		[newImage drawAtPoint:blitOrigin
					 fromRect:NSZeroRect
					operation:NSCompositeCopy 
					 fraction:1.0];
		[drawCanvas unlockFocus];
		[drawCanvas recache];
		
		[self createSnapshotOnUndoStack];
	}
	
	// reinit erase and result canvas
	DLOG(@"setDrawCanvas: release eraseCanvas: %@ %d", eraseCanvas, [eraseCanvas retainCount]);
	[eraseCanvas release];
	eraseCanvas = [[NSImage alloc] initWithSize:canvasSize];
	DLOG(@"setDrawCanvas: eraseCanvas: %@", eraseCanvas);
	NSAssert(eraseCanvas != nil, @"Failed to initialize canvas");
	
	DLOG(@"setDrawCanvas: release resultCanvas: %@ %d", resultCanvas, [resultCanvas retainCount]);
	[resultCanvas release];
	resultCanvas = [[NSImage alloc] initWithSize:canvasSize];
	DLOG(@"setDrawCanvas: resultCanvas: %@", resultCanvas);
	NSAssert(resultCanvas != nil, @"Failed to initialize canvas");
	
	shouldDrawPath = NO;
	[self setNeedsDisplay:YES];
}

- (void)setActiveTool:(Tool) tool {
	if (activeTool == TOOL_ERASER && tool != TOOL_ERASER) {
		// bake the erased bits into the draw canvas when switching away
		[self setDrawCanvas:resultCanvas];
	}
	
	activeTool = tool;
}

// pasteboard events
- (IBAction)copy:(id)sender {
	NSImage* image = resultCanvas;
	NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	NSArray* copiedImage = [NSArray arrayWithObject:image];
	[pasteboard writeObjects:copiedImage];
}

- (void)doPaste {
	NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
	NSArray* classArray = [NSArray arrayWithObject:[NSImage class]];
	NSDictionary* options = [NSDictionary dictionary];
	
	BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
	if (ok) {
		NSArray* objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
		NSImage* image = [objectsToPaste objectAtIndex:0];
		[self setDrawCanvas:image];
	}
}

- (void)pasteAlertEnded:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		[self doPaste];
	}
	[alert release];
}

- (IBAction)paste:(id)sender {
	if ([self.window isDocumentEdited]) {
		NSAlert* alert = [[[NSAlert alloc] init] retain];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Are you sure?"];
		[alert setInformativeText:@"Pasting into the sheet will lose your unsaved changes."];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:self.window
						  modalDelegate:self 
						 didEndSelector:@selector(pasteAlertEnded:returnCode:contextInfo:)
							contextInfo:nil];
	} else {
		[self doPaste];
	}
}

- (IBAction)undo:(id)sender {
	[[self undoManager] undo];
}

- (IBAction)redo:(id)sender {
	[[self undoManager] redo];
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
	
	NSLog(@"mouseDown: setting an undo point");
	[self createSnapshotOnUndoStack];
	switch (activeTool) {
		case TOOL_PENCIL:
			[[self undoManager] setActionName:@"Draw Pencil"];
			break;
		case TOOL_POINT:
			[[self undoManager] setActionName:@"Draw Point"];
			break;
		case TOOL_ERASER:
			[[self undoManager] setActionName:@"Erase"];
			break;
	}
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
		[self setDrawCanvas:resultCanvas];
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

- (void) clearAndRegisterUndo {
	[self createSnapshotOnUndoStack];
	[[self undoManager] setActionName:@"Clear"];
	[self clear];
}

- (void) clear {
	[self setDrawCanvas:nil];
}

- (void)saveToFile:(NSString*)filepath {
	NSBitmapImageRep* bm = [NSBitmapImageRep imageRepWithData:[resultCanvas TIFFRepresentation]];
	NSData* dataRep = [bm representationUsingType:NSPNGFileType properties:nil];
	
	BOOL success = [dataRep writeToFile:filepath atomically:YES];
	NSAssert1(success, @"Failed to save to %@", filepath);
}

- (BOOL) validateMenuItem:(NSMenuItem*) item {
	NSLog(@"Validating %@", item);
	if ([item action] == @selector(undo:))
		return [[self undoManager] canUndo];
	else if ([item action] == @selector(redo:))
		return [[self undoManager] canRedo];
	return YES;
}

@end
