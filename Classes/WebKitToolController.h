//
//  WebKitToolController.h
//  WebKitTool
//
//  Created by Joachim Fornallaz on 22.06.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DDCommandLineInterface.h"
#import "CaptureManager.h"


@interface WebKitToolController : NSObject <DDCliApplicationDelegate, CaptureManagerDelegate> {
    int _verbosity;
	float _browserWidth;
	NSPrintingOrientation _orientation;
    BOOL _paginate;
    BOOL _version;
    BOOL _help;
	int _exitCode;
}

- (void)printHelp;
- (void)printVersion;
- (void)printUsage:(FILE *)stream;

@end
