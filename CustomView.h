//
//  CustomView.h
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum eTool {
	TOOL_POINT,
	TOOL_PENCIL
} Tool;

@interface CustomView : NSView {
	@private
		NSImage* canvas;
		NSBezierPath* path;
		NSColor* brushColor;
		Tool activeTool;
		BOOL shouldDrawPath;
}

- (void)setBrushColor:(NSColor *) color;
- (void)setActiveTool:(Tool) tool;

- (NSPoint) convertMousePointToViewLocation:(NSPoint) pt;

@end
