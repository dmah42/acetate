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
		NSLog(@"Main window initialized");
		[self setAlphaValue:1.0];
        [self setOpaque:NO];
	}
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (void)clearAlertEnded:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		[[self contentView] clear];
	}
}

- (IBAction)clearAcetate:(id)sender {
	if ([self isDocumentEdited]) {
		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
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
		[[self contentView] clear];
	}
}

@end
