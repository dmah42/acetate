//
//  Controller.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import "Controller.h"

@implementation Controller

- (void)windowDidLoad {
	[super windowDidLoad];
	
	[toolbarPanel setFloatingPanel:YES];
	[toolbarPanel setBecomesKeyOnlyIfNeeded:YES];
	
	[self.window makeKeyAndOrderFront:self];
}

- (IBAction)toggleToolbarPanel:(id)sender {
	if ([toolbarPanel isVisible]) {
		[toolbarPanel orderOut:sender];
	} else {
		[toolbarPanel orderFront:sender];
	}
}

// window delegate overrides
- (void)windowWillClose:(NSNotification*) notification {
	if ([notification object] != toolbarPanel) {
		toolbar_was_visible = [toolbarPanel isVisible];
		if (toolbar_was_visible) {
			[toolbarPanel orderOut:self];
		}
		
		closed_window = [notification object];
	}
}


// app delegate overrides
- (BOOL) applicationShouldHandleReopen:(NSApplication*)theApplication 
					 hasVisibleWindows:(BOOL)flag {
	if (flag == NO) {
		[self showWindow:closed_window];
		if (toolbar_was_visible) {
			[self toggleToolbarPanel:closed_window];
		}
	}
	return YES;
}

@end
