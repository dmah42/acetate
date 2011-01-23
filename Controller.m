//
//  Controller.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import "Controller.h"
#import "CustomView.h"

#import <AppKit/AppKit.h>

@implementation Controller

- (IBAction)toggleToolbarPanel:(id)sender {
	NSLog(@"Toggling toolbar panel");
	if ([toolbarPanel isVisible]) {
		[toolbarPanel orderOut:sender];
	} else {
		[toolbarPanel orderFront:sender];
		[toolbarPanel setLevel:[self.window level]];
	}
}


- (IBAction)togglePushPin:(id)sender {
	NSButton* pushpin = (NSButton*) sender;
	NSInteger state = [pushpin state];
	switch (state) {
		case NSOffState:
			[self.window setMovable:YES];
			break;
		case NSOnState:
			[self.window setMovable:NO];
			break;
		case NSMixedState:
			NSAssert(false, @"Unexpected mixed state for pushpin");
			break;
		default:
			NSAssert1(false, @"Unknown state %d for pushpin", state);
			break;
	}	
}

- (IBAction)toggleFloating:(id)sender {
	NSButton* floater = (NSButton*) sender;
	NSInteger state = [floater state];
	switch (state) {
		case NSOffState:
			[toolbarPanel setLevel:NSNormalWindowLevel];
			[self.window setLevel:NSNormalWindowLevel];
			break;
		case NSOnState:
			[toolbarPanel setLevel:NSFloatingWindowLevel];
			[self.window setLevel:NSFloatingWindowLevel];
			break;
		case NSMixedState:
			NSAssert(false, @"Unexpected mixed state for floater");
			break;
		default:
			NSAssert1(false, @"Unknown state %d for floater", state);
			break;
	}
}

- (IBAction)setActiveTool:(id)sender {
	NSMatrix* tools = (NSMatrix*)sender;
	id selectedCell = [tools selectedCell];
	NSAssert(selectedCell != nil, @"No selected tool");
	
	NSButtonCell* selectedButtonCell = (NSButtonCell*) selectedCell;
	
	CustomView* customView = [self.window contentView];
	
	if (selectedButtonCell == pointTool)
		[customView setActiveTool:TOOL_POINT];
	else if (selectedButtonCell == pencilTool)
		[customView setActiveTool:TOOL_PENCIL];
	else if (selectedButtonCell == eraserTool)
		[customView setActiveTool:TOOL_ERASER];
	else			
		NSAssert(false, @"Unexpected tool button");
}

- (void)changeColor:(id) sender {
	NSColorPanel* colorPanel = (NSColorPanel*) sender;
	CustomView* customView = [self.window contentView];
	[customView setBrushColor:[colorPanel color]];
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
+ (void)initialize {
	if (self == [Controller class]) {
		// print some info
		NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
		NSString *appVersionNumber = [infoDict objectForKey:@"CFBundleVersion"];
		NSString *appVersionString = [infoDict valueForKey:@"CFBundleShortVersionString"];
		NSString *buildDateString = [infoDict objectForKey:@"CFBuildDate"];
		
		NSLog(@"Acetate version %@, build %d on %@",
			  appVersionString, appVersionNumber, buildDateString);
		
		// set defaults
		NSString* defaultsFile = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
		NSDictionary* defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsFile];
		NSLog(@"Setting defaults:");
		NSEnumerator* defaultsEnum = [defaultsDict keyEnumerator];
		id key;
		while ((key = [defaultsEnum nextObject])) {
			NSLog(@"  %@ -> %@", key, [defaultsDict valueForKey:key]);
		}
		
		NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults registerDefaults:defaultsDict];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification*) aNotification {
	[toolbarPanel setFloatingPanel:YES];
	[toolbarPanel setBecomesKeyOnlyIfNeeded:YES];
	
	[self.window makeKeyAndOrderFront:self];
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
