//
//  WebKitToolController.m
//  WebKitTool
//
//  Created by Joachim Fornallaz on 22.06.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import "WebKitToolController.h"
#import "Version.h"


@implementation WebKitToolController

#pragma mark DDCliApplicationDelegate methods

- (void)setOrientation:(NSString *)orientation
{
    if ([orientation isEqualToString:@"portrait"]) {
		_orientation = NSPortraitOrientation;
	} else if ([orientation isEqualToString:@"landscape"]) {
		_orientation = NSLandscapeOrientation;
	} else {
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"Invalid orientation '%@'", orientation] exitCode:EX_USAGE];
    }
}

- (void)setBrowserWidth:(NSString *)width
{
	_browserWidth = [width floatValue];
	if (_browserWidth <= 0.0) {
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"Invalid browser-width %f", _browserWidth] exitCode:EX_USAGE];
	}
}

- (void)application:(DDCliApplication *)app willParseOptions:(DDGetoptLongParser *)optionsParser
{
    [optionsParser setGetoptLongOnly: YES];
    DDGetoptOption optionTable[] = 
    {
        // Long             Short   Argument options
        {@"paginate",       'p',    DDGetoptNoArgument},
        {@"orientation",    'o',    DDGetoptRequiredArgument},
        {@"browser-width",  'w',    DDGetoptRequiredArgument},
        {@"header-left-js",  0,     DDGetoptRequiredArgument},
        {@"header-right-js", 0,     DDGetoptRequiredArgument},
        {@"footer-left-js",  0,     DDGetoptRequiredArgument},
        {@"footer-right-js", 0,     DDGetoptRequiredArgument},
        {@"version",         0,     DDGetoptNoArgument},
        {@"help",           'h',    DDGetoptNoArgument},
        {nil,                0,     0},
    };
    [optionsParser addOptionsFromTable: optionTable];
}

- (int)application:(DDCliApplication *)app runWithArguments:(NSArray *)arguments
{
	if (_help) {
        [self printHelp];
        return EXIT_SUCCESS;
    }	

	if (_version)
    {
        [self printVersion];
        return EXIT_SUCCESS;
    }
	
    if ([arguments count] < 2) {
        ddfprintf(stderr, @"%@: You need to specify one input file and one output file\n", DDCliApp);
        [self printUsage: stderr];
        ddfprintf(stderr, @"Try `%@ --help' for more information.\n", DDCliApp);
        return EX_USAGE;
    }
	
	NSString *urlString = [arguments objectAtIndex:0];
	NSArray *components = [urlString componentsSeparatedByString:@"://"];
	if ([components count] == 1) {
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	}
	NSURL *webURL = [NSURL URLWithString:urlString];
	if (webURL == nil) {
        ddfprintf(stderr, @"%@: Could not parse '%@' as URL\n", DDCliApp, [arguments objectAtIndex:0]);
        [self printUsage: stderr];
	}
	
	NSString *outputPath = [arguments objectAtIndex:1];
	
	NSMutableDictionary *headerAndFooterJavaScriptDict = [NSMutableDictionary dictionaryWithCapacity:4];
	if (_headerLeftJs)
		[headerAndFooterJavaScriptDict setObject:_headerLeftJs forKey:@"headerLeft"];
	if (_headerRightJs)
		[headerAndFooterJavaScriptDict setObject:_headerRightJs forKey:@"headerRight"];
	if (_footerLeftJs)
		[headerAndFooterJavaScriptDict setObject:_footerLeftJs forKey:@"footerLeft"];
	if (_footerRightJs)
		[headerAndFooterJavaScriptDict setObject:_footerRightJs forKey:@"footerRight"];
	
	_exitCode = EXIT_SUCCESS;
	CaptureManager *manager = [[CaptureManager alloc] initWithURL:webURL outputPath:outputPath];
	[manager setDelegate:self];
	[manager setPaginate:_paginate];
	[manager setPrintingOrientation:_orientation];
	[manager setPrintingHeaderAndFooterJavaScript:headerAndFooterJavaScriptDict];
	[manager startCapture];
		
    return _exitCode;
}

#pragma mark CaptureManagerDelegate methods

- (void)captureManager:(CaptureManager *)manager didFailWithError:(NSError *)error
{
	_exitCode = EXIT_FAILURE;
	ddfprintf(stderr, [error localizedDescription]);
}

#pragma mark -

- (void)printHelp
{
    [self printUsage: stdout];
    printf("\n"
           "  -w, --browserwidth            Set browser withd in pixel.\n"
           "  -p, --paginage                Create multipage PDF\n"
           "  -o, --orientation             Set PDF orientation: 'portrait' or 'landscape'\n"
           "      --header-left-js          Set PDF left header:  JavaScript expression\n"
           "      --header-right-js         Set PDF right header: JavaScript expression\n"
           "      --footer-left-js          Set PDF left footer:  JavaScript expression\n"
           "      --footer-right-js         Set PDF right footer: JavaScript expression\n"
           "      --version                 Display version and exit\n"
           "  -h, --help                    Display this help and exit\n"
           "\n"
           "A command line tool using WebKit for converting web sites to PDFs.\n");
}

- (void) printVersion;
{
    ddprintf(@"%@ version %s\n", DDCliApp, CURRENT_MARKETING_VERSION);
}

- (void)printUsage:(FILE *)stream
{
    ddfprintf(stream, @"%@: Usage [OPTIONS] <input address> <output file>\n", DDCliApp);
	ddfprintf(stream, @"See http://github.com/fjoachim/webkittool for details.\n");
}

@end
