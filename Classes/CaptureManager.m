//
//  CaptureManager.m
//  SiteCaptureTool
//
//  Created by Joachim Fornallaz on 22.06.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import "CaptureManager.h"


CaptureOutputFormat CaptureOutputFormatForFile(NSString *path)
{
	CaptureOutputFormat format = -1;
	NSString *extension = [[path pathExtension] lowercaseString];
	if ([extension isEqualToString:@"pdf"]) {
		format = CaptureFormatPDF;
	} else if ([extension isEqualToString:@"png"]) {
		format = CaptureFormatPNG;
	} else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
		format = CaptureFormatJPEG;
	}
	return format;
}

NSBitmapImageFileType NSBitmapImageFileTypeFromCaptureOutputFormat(CaptureOutputFormat format)
{
	NSBitmapImageFileType fileType = NSTIFFFileType;
	if (format == CaptureFormatPNG) {
		fileType = NSPNGFileType;
	} else if (format == CaptureFormatJPEG) {
		fileType = NSJPEGFileType;
	}
	return fileType;
}


@interface CaptureManager (Private)

- (WebView *)webView;
- (NSWindow *)embedWebViewInWindow;
- (void)writePDF:(WebView *)sender;
- (void)writePaginatedPDF:(WebView *)sender;
- (void)writeBitmap:(WebView *)sender format:(CaptureOutputFormat)format;

@end


@implementation CaptureManager

- (id)initWithURL:(NSURL *)anURL outputPath:(NSString *)anOutputPath
{
	self = [super init];
	if (self != nil) {
		theURL = [anURL copy];
		ouputPath = [anOutputPath copy];
		finished = NO;
		paginate = NO;
		printingOrientation = NSPortraitOrientation;
		paperSize = NSMakeSize(595,842);
		browserWidth = 800.0;
	}
	return self;
}

- (void)dealloc
{
	[ouputPath release];
	[theURL release];
	[super dealloc];
}

#pragma mark Accessor methods

- (void)setDelegate:(id<CaptureManagerDelegate>)aDelegate;
{
	delegate = aDelegate;
}

- (void)setPaginate:(BOOL)doPaginate
{
	paginate = doPaginate;
}

- (void)setPaperSize:(NSSize)size
{
	paperSize = size;
}

- (void)setPrintingOrientation:(NSPrintingOrientation)orientation
{
	printingOrientation = orientation;
}

- (void)setBrowserWidth:(float)width
{
	browserWidth = width;
}

- (WebView *)webView
{
	static WebView *webView = nil;

	if (webView == nil) {
		WebPreferences *preferences = [WebPreferences standardPreferences];
		[preferences setShouldPrintBackgrounds:YES];
		
		webView = [[WebView alloc] initWithFrame:NSMakeRect(0.0, 0.0, browserWidth, 1.0) frameName:@"frame" groupName:@"group"];
		[webView setFrameLoadDelegate:self];
		[webView setMediaStyle:@"screen"];
		[webView setPreferences:preferences];		
	}
	
	return webView;
}

- (NSWindow *)embedWebViewInWindow
{
	static NSWindow *window = nil;

	if (window == nil) {
		[NSApplication sharedApplication];
		window = [[NSWindow alloc] initWithContentRect:[[self webView] bounds] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		[window setContentView:[self webView]];
	}
	
	return window;
}

#pragma mark Action methods

- (void)startCapture
{
	[[[self webView] mainFrame] loadRequest:[NSURLRequest requestWithURL:theURL]];
	while (!finished) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}
}

#pragma mark Private methods

- (void)writePDF:(WebView *)sender
{
	NSView *documentView = [[[sender mainFrame] frameView] documentView];
	NSRect bounds = [documentView bounds];
	NSData *pdfData = [documentView dataWithPDFInsideRect:bounds];
	[pdfData writeToFile:ouputPath atomically:NO];	
}

- (void)writePaginatedPDF:(WebView *)sender
{
	[self embedWebViewInWindow];
	NSPrintInfo *sharedPrintInfo = [NSPrintInfo sharedPrintInfo];
	NSMutableDictionary *printInfoDict = [[sharedPrintInfo dictionary] mutableCopy];
	[printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
	[printInfoDict setObject:ouputPath forKey:NSPrintSavePath];

	NSPrintInfo *printInfo = [[NSPrintInfo alloc] initWithDictionary:printInfoDict];
	[printInfo setHorizontalPagination:NSAutoPagination];
	[printInfo setVerticalPagination:NSAutoPagination];
	[printInfo setHorizontallyCentered:YES];
	[printInfo setVerticallyCentered:NO];
	[printInfo setOrientation:printingOrientation];
	[printInfo setPaperSize:paperSize];
	[printInfo setTopMargin:16.0];
	[printInfo setRightMargin:16.0];
	[printInfo setBottomMargin:16.0];
	[printInfo setLeftMargin:16.0];
	
	NSView *documentView = [[[sender mainFrame] frameView] documentView];
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:documentView printInfo:printInfo];
	[printOperation setShowPanels:NO];
	[printOperation runOperation];
}

- (void)writeBitmap:(WebView *)sender format:(CaptureOutputFormat)format
{
	NSWindow *window = [self embedWebViewInWindow];
	NSView *documentView = [[[sender mainFrame] frameView] documentView];
	NSRect documentViewFrame = [documentView frame];
	NSRect webViewFrame = [sender frame];
	if (webViewFrame.size.height < documentViewFrame.size.height) {
		NSSize webViewFrameSize = webViewFrame.size;
		webViewFrameSize.height = documentViewFrame.size.height;
		[window setContentSize:webViewFrameSize];
	}
	[sender lockFocus];
	NSBitmapImageRep *pageImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[sender bounds]];
	[sender unlockFocus];
	NSBitmapImageFileType fileType = NSBitmapImageFileTypeFromCaptureOutputFormat(format);
	NSData *imageData = [pageImageRep representationUsingType:fileType properties:[NSDictionary dictionary]];
	[imageData writeToFile:ouputPath atomically:NO];
}

#pragma mark WebFrameLoadDelegate methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{

}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if (frame == [sender mainFrame]) {
		finished = YES;
		[delegate captureManager:self didFailWithError:error];
	}
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if (frame == [sender mainFrame]) {
		finished = YES;
		[delegate captureManager:self didFailWithError:error];
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	if (frame == [sender mainFrame]) {
		finished = YES;
		CaptureOutputFormat format = CaptureOutputFormatForFile(ouputPath);
		switch (format) {
			case CaptureFormatPDF:
				if (paginate) {
					[self writePaginatedPDF:sender];
				} else {
					[self writePDF:sender];
				}				
				break;
			case CaptureFormatPNG:
			case CaptureFormatJPEG:
				[self writeBitmap:sender format:format];
				break;
			default:
				[delegate captureManager:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil]];
				break;
		}
		
	}
}

@end
