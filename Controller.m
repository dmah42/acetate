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
	DLOG(@"Toggling toolbar panel");
	if ([toolbarPanel isVisible]) {
		[toolbarPanel orderOut:sender];
	} else {
		[toolbarPanel orderFront:sender];
			
		NSInteger windowLevel = [self.window level];
		if (windowLevel == NSNormalWindowLevel) {
			[toolbarPanel setLevel:NSFloatingWindowLevel];
		} else if (windowLevel == NSFloatingWindowLevel) {
			[toolbarPanel setLevel:NSPopUpMenuWindowLevel];
		} else {
			NSAssert(false, @"Unexpected level for main window");
		}
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
			[toolbarPanel setLevel:NSFloatingWindowLevel];
			[self.window setLevel:NSNormalWindowLevel];
			break;
		case NSOnState:
			[toolbarPanel setLevel:NSPopUpMenuWindowLevel];
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

- (void)windowDidResize:(NSNotification *)notification {
	NSWindow* window = [notification object];
	
	NSAssert(window == self.window, @"Wrong window encountered");
	
	CustomView* customView = (CustomView*) [self.window contentView];
	[customView onResize];
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
		DLOG(@"Setting defaults:");
		NSEnumerator* defaultsEnum = [defaultsDict keyEnumerator];
		id key;
		while ((key = [defaultsEnum nextObject])) {
			DLOG(@"  %@ -> %@", key, [defaultsDict valueForKey:key]);
		}
		
		NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults registerDefaults:defaultsDict];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification*) aNotification {
	[toolbarPanel setFloatingPanel:YES];
	[toolbarPanel setBecomesKeyOnlyIfNeeded:YES];
	[toolbarPanel setLevel:NSFloatingWindowLevel];
	
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

// file menu options
/*
- (void)openDocument:(id)sender {
	BOOL shouldOpen = YES;
	if ([self.window isDocumentEdited]) {
		int iResponse = NSRunAlertPanel(@"New sheet", 
										@"Are you sure you want to create a new sheet? This will clear your current sheet.",
										@"OK", @"Cancel", nil);
		if (iResponse != NSAlertDefaultReturn) {
			shouldOpen = NO;
		}
	}
	
	if (shouldOpen) {
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		NSArray* fileTypeArray = [NSArray arrayWithObject:@"ace"];
		[openPanel setAllowedFileTypes:fileTypeArray];
		[openPanel setCanChooseFiles:YES];
		[openPanel setCanChooseDirectories:NO];
		[openPanel setAllowsMultipleSelection:NO];
	
		[openPanel beginWithCompletionHandler:^(NSInteger returnCode) {
			if (returnCode == NSFileHandlingPanelOKButton) {
				filePath = [[openPanel URLs] objectAtIndex:0];
				
				NSString* title = [NSString stringWithFormat:@"Acetate - %@", filePath];
				[self.window setTitle:title];

				// TODO: create new window with image file
				[self newAcetate:sender];
//				[[self.window contentView] initializeWithFile:filePath];
			}
		}];
	}
}

- (void)saveDocument:(id)sender {
	if ([self.window isDocumentEdited]) {
		if (filePath == nil) {
			[self saveDocumentAs:sender];
		} else {
			[[self.window contentView] saveToFile:filePath];
		}
	}
}

- (void)saveDocumentAs:(id)sender {
	NSSavePanel* savePanel = [NSSavePanel savePanel];
	NSArray* fileTypeArray = [NSArray arrayWithObject:@"ace"];
	[savePanel setAllowedFileTypes:fileTypeArray];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel setExtensionHidden:YES];
	[savePanel setCanSelectHiddenExtension:YES];
	
	if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
		filePath = [[savePanel URL] absoluteString];
		NSString* title = [NSString stringWithFormat:@"Acetate - %@", filePath];
		[self.window setTitle:title];
		[[self.window contentView] saveToFile:filePath];
	}
}

// TODO
- (void)newAcetate:(id)sender {
}
*/
@end
