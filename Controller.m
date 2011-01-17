//
//  Controller.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import "Controller.h"

@implementation Controller

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
- (void)applicationDidFinishLaunching:(NSNotification*) aNotification {
	[toolbarPanel setFloatingPanel:YES];
	[toolbarPanel setBecomesKeyOnlyIfNeeded:YES];
	
	[self.window makeKeyAndOrderFront:self];
	
	// print some info
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *appVersionNumber = [infoDict objectForKey:@"CFBundleVersion"];
    NSString *buildNumber = [infoDict valueForKey:@"CFBuildNumber"];
    NSString *buildDateString = [infoDict objectForKey:@"CFBuildDate"];
	
	NSLog(@"Acetate version %@, build %d on %@",
		  appVersionNumber, buildNumber, buildDateString);
}

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
