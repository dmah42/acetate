//
//  Controller.h
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface Controller : NSWindowController {
	IBOutlet NSPanel* toolbarPanel;
	IBOutlet NSMatrix* toolMatrix;
	IBOutlet NSButtonCell* pencilTool;
	IBOutlet NSButtonCell* pointTool;
	IBOutlet NSButtonCell* eraserTool;
	@private
		NSWindow* closed_window;
		BOOL toolbar_was_visible;
		NSString* filePath;
}

- (IBAction)toggleFloating:(id)sender;
- (IBAction)toggleToolbarPanel:(id)sender;
- (IBAction)togglePushPin:(id)sender;
- (IBAction)setActiveTool:(id)sender;
/*
- (IBAction)newAcetate:(id)sender;
- (void)saveDocumentAs:(id)sender;
*/	
@end
