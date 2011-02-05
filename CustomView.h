//
//  CustomView.h
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum eTool {
	TOOL_PENCIL,
	TOOL_POINT,
	TOOL_ERASER
} Tool;

@interface CustomView : NSView {
	@private
		NSImage* resultCanvas;
		NSImage* drawCanvas;
		NSImage* eraseCanvas;
		NSBezierPath* path;
		NSColor* brushColor;
		Tool activeTool;
		BOOL shouldDrawPath;
}

- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;

- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;

- (void)setBrushColor:(NSColor *) color;
- (void)setActiveTool:(Tool) tool;

- (NSPoint) convertMousePointToViewLocation:(NSPoint) pt;

- (void)clearAndRegisterUndo;
- (void)clear;

- (void)saveToFile:(NSString*)filepath;

- (void)onResize;

@end
