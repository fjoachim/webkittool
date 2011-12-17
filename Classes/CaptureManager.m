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
- (NSAttributedString *)attributedStringWithString:(NSString *)aString textAlignment:(NSTextAlignment)alignment;
- (void)setPrintInfoForWebView:(WebView *)webView;
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
		printingHeaderAndFooterJavaScript = nil;
		paperSize = NSMakeSize(595,842);
		browserWidth = 800.0;
	}
	return self;
}

- (void)dealloc
{
	[printingHeaderAndFooterJavaScript release];
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

- (void)setPrintingHeaderAndFooterJavaScript:(NSDictionary *)dict
{
	printingHeaderAndFooterJavaScript = [dict retain];
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
		[webView setUIDelegate:self];
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

- (NSAttributedString *)attributedStringWithString:(NSString *)aString textAlignment:(NSTextAlignment)alignment
{
	NSFont *stringFont = [NSFont fontWithName:@"Helvetica" size:8.0];
	NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject:stringFont forKey:NSFontAttributeName];
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:aString attributes:stringAttributes];
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setAlignment:alignment];
	[attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attributedString length])];
	[paragraphStyle release];
	return [attributedString autorelease];
}

- (void)setPrintInfoForWebView:(WebView *)webView
{
	NSPrintOperation *printOperation = [NSPrintOperation currentOperation];
	int currentPage = [printOperation currentPage];
	int pageCount = 0;
	NSRange pageRange;
	BOOL success = [[printOperation view] knowsPageRange:&pageRange];
	if (success) {
		pageCount = pageRange.length;
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.printInfo = { currentPage: %d, pageCount: %d }", currentPage, pageCount]];
}

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

	WebFrameView *frameView = [[sender mainFrame] frameView];
	NSPrintOperation *printOperation = [frameView printOperationWithPrintInfo:printInfo];
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

#pragma mark WebUIDelegate methods

- (float)webViewHeaderHeight:(WebView *)sender
{
	BOOL hasHeader = [printingHeaderAndFooterJavaScript objectForKey:@"headerLeft"] || [printingHeaderAndFooterJavaScript objectForKey:@"headerRight"];
	return hasHeader ? 20.0 : 0.0;
}

- (void)webView:(WebView *)sender drawHeaderInRect:(NSRect)rect
{
	[self setPrintInfoForWebView: sender];
	float halfWidth = rect.size.width / 2.0;

	NSString *leftJavaScript = [printingHeaderAndFooterJavaScript objectForKey:@"headerLeft"];
	if (leftJavaScript) {
		NSString *string = [sender stringByEvaluatingJavaScriptFromString:leftJavaScript];
		NSAttributedString *attributedString = [self attributedStringWithString:string textAlignment:NSLeftTextAlignment];
		NSRect leftRect = NSMakeRect(rect.origin.x, rect.origin.y, halfWidth, rect.size.height);
		[attributedString drawInRect:leftRect];
	}

	NSString *rightJavaScript =[printingHeaderAndFooterJavaScript objectForKey:@"headerRight"];
	if (rightJavaScript) {
		NSString *string = [sender stringByEvaluatingJavaScriptFromString:rightJavaScript];
		NSAttributedString *attributedString = [self attributedStringWithString:string textAlignment:NSRightTextAlignment];
		NSRect rightRect = NSMakeRect(rect.origin.x + halfWidth, rect.origin.y, halfWidth, rect.size.height);
		[attributedString drawInRect:rightRect];
	}
}

- (float)webViewFooterHeight:(WebView *)sender
{
	BOOL hasFooter = [printingHeaderAndFooterJavaScript objectForKey:@"footerLeft"] || [printingHeaderAndFooterJavaScript objectForKey:@"footerRight"];
	return hasFooter ? 20.0 : 0.0;
}

- (void)webView:(WebView *)sender drawFooterInRect:(NSRect)rect
{
	[self setPrintInfoForWebView: sender];
	float halfWidth = rect.size.width / 2.0;
	rect.origin.y -= 4.0;
	rect.size.height -= 4.0;

	NSString *leftJavaScript = [printingHeaderAndFooterJavaScript objectForKey:@"footerLeft"];
	if (leftJavaScript) {
		NSString *string = [sender stringByEvaluatingJavaScriptFromString:leftJavaScript];
		NSAttributedString *attributedString = [self attributedStringWithString:string textAlignment:NSLeftTextAlignment];
		NSRect leftRect = NSMakeRect(rect.origin.x, rect.origin.y, halfWidth, rect.size.height);
		[attributedString drawInRect:leftRect];
	}

	NSString *rightJavaScript =[printingHeaderAndFooterJavaScript objectForKey:@"footerRight"];
	if (rightJavaScript) {
		NSString *string = [sender stringByEvaluatingJavaScriptFromString:rightJavaScript];
		NSAttributedString *attributedString = [self attributedStringWithString:string textAlignment:NSRightTextAlignment];
		NSRect rightRect = NSMakeRect(rect.origin.x + halfWidth, rect.origin.y, halfWidth, rect.size.height);
		[attributedString drawInRect:rightRect];
	}
}

@end
