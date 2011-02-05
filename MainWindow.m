//
//  MainWindow.m
//  Acetate
//
//  Created by Dominic Hamon on 13/1/11.
//  Copyright 2011 stripysock.com. All rights reserved.
//

#import "CustomView.h"
#import "MainWindow.h"
#import <AppKit/AppKit.h>

@implementation MainWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle
				                              backing:(NSBackingStoreType)bufferingType
					                          defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect
				  styleMask:(NSResizableWindowMask | NSClosableWindowMask)
				  backing:NSBackingStoreBuffered defer:NO];
	NSAssert(self != nil, @"Failed to initialize Main window");
    if (self != nil) {
		DLOG(@"Main window initialized");
		[self setAlphaValue:1.0];
        [self setOpaque:NO];
		[self setHasShadow:NO];
	}
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (void)clearAlertEnded:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		[[self contentView] clearAndRegisterUndo];
	}
	[alert release];
}

- (IBAction)clearAcetate:(id)sender {
	if ([self isDocumentEdited]) {
		NSAlert* alert = [[[NSAlert alloc] init] retain];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Are you sure?"];
		[alert setInformativeText:@"Clearing the sheet will lose your unsaved changes."];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:self 
						  modalDelegate:self 
						 didEndSelector:@selector(clearAlertEnded:returnCode:contextInfo:)
							contextInfo:nil];
	} else {
		[[self contentView] clearAndRegisterUndo];
	}
}

- (void)cutAlertEnded:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		id sender = (id)contextInfo;
		[[self contentView] copy:sender];
		[[self contentView] clearAndRegisterUndo];
	}
	[alert release];
}

- (IBAction)cut:(id)sender {
	if ([self isDocumentEdited]) {
		NSAlert* alert = [[[NSAlert alloc] init] retain];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Are you sure?"];
		[alert setInformativeText:@"Cutting will lose your unsaved changes."];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:self 
						  modalDelegate:self 
						 didEndSelector:@selector(cutAlertEnded:returnCode:contextInfo:)
							contextInfo:(void*) sender];
	} else {
		[[self contentView] copy:sender];
		[[self contentView] clearAndRegisterUndo];
	}	
}

@end
