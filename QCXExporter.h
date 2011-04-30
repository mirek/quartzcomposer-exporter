//
// QCXExporterPlugIn.h
// QCXExporter
//
// Created by Mirek Rusin on 24/01/2010.
// Copyright (c) 2010 Inteliv Ltd. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <QTKit/QTKit.h>

// It's highly recommended to use CGL macros instead of changing
// the current context for plug-ins that perform OpenGL rendering
#import <OpenGL/CGLMacro.h>

typedef enum {
  kQCXExporterStateIdle,
  kQCXExporterStateRecording,
  kQCXExporterStateSaving
} QCXExporterState;

// Movie exporter patch for Quartz Composer. The export process is handled in two phases:
//
// 1. Capturing - fast frame capture without intensive encoding
// 2. Exporting - proper compression (mpv4 or hxxx codecs)
//
// Handling the process in two stages allows Quartz Composer to use maximum CPU power when
// playing the composition.
@interface QCXExporter : QCPlugIn {
  
  NSTimeInterval lastImageAddedAt;

  NSImage *lastImage;
  NSMutableData *data;
  QTMovie *movie;
  id delegate;
  
  // The sample* ivars are captured on the frame -1
  // We're using it to allocate properly sized buffers which depend on the size of the image (really? we should rely on NSData)
  NSInteger sampleBufferPixelsWide;
  NSInteger sampleBufferPixelsHigh;
  NSInteger sampleBufferBytesPerRow;
  const void *sampleBufferBaseAddress;
  NSString *sampleBufferPixelFormat;
  NSRect sampleImageBounds;
  CGColorSpaceRef sampleImageColorSpace;
  
  NSTimeInterval lastCaptureAt;
  NSMutableArray *rawImageDataArray;
  NSMutableArray *rawQueue;
  NSInteger frame;
  
  // To read FPS value, use lastSecondFps as it's always going to have
  // proper value. The fps value on the other hand is being updated
  // during the current second, so there's no sense in reading this value.
  NSInteger fps;
  NSInteger lastSecondFps;
  bool secondSwap;
  
  BOOL isExportingPaused;
  BOOL isExportingStopped;
  BOOL isExportingCancelled;
  
  NSUInteger threadCount;
  
  QCXExporterState state;
}

// String representation of the the first grabbed frame (sample)
@property (retain, readonly) NSString *sampleInfo;

// Number of threads currently used in recording phase. This shouldn't be more
// than 1-3 max.
@property (assign) NSUInteger threadCount;

// Recording time in HH:MM:SS format
@property (retain, readonly) NSString  *recordingTime;

// Number of frames per second recorded in the last second
@property (assign) NSInteger lastSecondFps;

// The time interval between the reference date of the last captured frame
@property (assign) NSTimeInterval lastCaptureAt;

// Control flag for exporting phase. Set it directly to YES to pause exporting,
// alternativelly you can send [QCXExporter pause] or [QCXExporter resume] messages.
@property (assign) IBOutlet BOOL isExportingPaused;

// TODO: remove from public api
@property (assign) IBOutlet BOOL isExportingStopped;

// TODO: remove from public api
@property (assign) IBOutlet BOOL isExportingCancelled;

// The current state, for available values see QCXExporterState enum.
@property (assign) QCXExporterState state;

#pragma mark Inputs and outputs

// Input image to be fed (usually from `Render in Image` patch)
@property (retain) id<QCPlugInInputImageSource> inputImage;

// The time scale of exported file. This can value can be animated.
// For example time scale set to 0.5 will result in movie playing half of the time (and double accuracy)
@property (assign) double inputTimeScale;

// Flag controlling the recording
@property (assign) BOOL inputRecord;

#pragma mark Methods

// TODO: change it to endRecording
- (void) save;

// Captures an image
- (BOOL) captureWithNSImage: (NSImage *) nsImage;

// Captures an image with parameters
- (BOOL) captureWithParams: (NSDictionary *) params;
- (BOOL) takeSampleWithQCImage: (id<QCPlugInInputImageSource>) qcImage;
- (NSString *) pixelFormatWithColorSpace: (CGColorSpaceRef) colorSpace;
- (NSImage *) nsImageWithQCImage: (id<QCPlugInInputImageSource>) qcImage convertToTIFF: (BOOL) convertToTIFF lockBuffer: (BOOL) lockBuffer unlockBuffer: (BOOL) unlockBuffer;

#pragma mark Recording

- (void) addNSImageAsMPEG4: (NSImage *) image;
- (void) addNSImageAsMPEG4: (NSImage *) image at: (NSTimeInterval) at timeScale: (double) timeScale;
- (BOOL) flattenToFile: (NSString *) path;
- (BOOL) flattenToFile: (NSString *) path error: (NSError **) error;

#pragma mark Actions

// TODO: Rename to startCapture
- (void) startRecording;

// TODO: Rename to endCapture
- (void) stopRecording;

// Pause exporting, see also `QCXMovie pauseExporting` property.
- (void) pauseExporting;

// Resume exporting, see also `QCXMovie pauseExporting` property.
- (void) resumeExporting;

// Stop exporting at the current frame. Movie file will be flattened from already processed frames.
// All unprocessed frames are discarded.
- (void) finishExporting;

// Immediatelly terminate exporting
- (void) cancelExporting;

@end
