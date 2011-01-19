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
	@private
		NSWindow* closed_window;
		BOOL toolbar_was_visible;
}

- (IBAction)toggleToolbarPanel:(id)sender;
- (IBAction)togglePushPin:(id)sender;

@end
