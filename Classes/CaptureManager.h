//
//  CaptureManager.h
//  SiteCaptureTool
//
//  Created by Joachim Fornallaz on 22.06.10.
//  Copyright 2010 Joachim Fornallaz. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

typedef enum {
    CaptureFormatPDF = 0,
    CaptureFormatPNG = 1,
    CaptureFormatJPEG = 2
} CaptureOutputFormat;


@protocol CaptureManagerDelegate;


@interface CaptureManager : NSObject {
	NSURL *theURL;
	NSString *ouputPath;
	CaptureOutputFormat outputFormat;
	BOOL paginate;
	NSSize paperSize;
	NSPrintingOrientation printingOrientation;
	float browserWidth;
	id<CaptureManagerDelegate> delegate;
@private
	BOOL finished;
}

- (id)initWithURL:(NSURL *)anURL outputPath:(NSString *)anOutputPath;
- (void)startCapture;
- (void)setDelegate:(id<CaptureManagerDelegate>)aDelegate;
- (void)setPaginate:(BOOL)doPaginate;
- (void)setPaperSize:(NSSize)size;
- (void)setPrintingOrientation:(NSPrintingOrientation)orientation;
- (void)setBrowserWidth:(float)width;

@end


@protocol CaptureManagerDelegate

- (void)captureManager:(CaptureManager *)manager didFailWithError:(NSError *)error;

@end

