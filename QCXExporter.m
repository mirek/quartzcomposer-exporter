//
//  QCXExporterPlugIn.m
//  QCXExporter
//
//  Created by Mirek Rusin on 24/01/2010.
//  Copyright (c) 2010 Inteliv Ltd. All rights reserved.
//

#import "QCXExporter.h"
#import "QCXExporterSettings.h"

NSDictionary *QCXExporter_Info;

@implementation QCXExporter

@dynamic inputImage;
@dynamic inputTimeScale;
@dynamic inputRecord;

@synthesize lastCaptureAt;
@synthesize threadCount;
@synthesize state;

@synthesize isExportingPaused;
@synthesize isExportingStopped;
@synthesize isExportingCancelled;

//@synthesize sampleBufferPixelsWide;
//@synthesize sampleBufferPixelsHigh;
@synthesize lastSecondFps;

+ (NSDictionary *) plugInInfo {
  if (QCXExporter_Info == nil) {
    NSString *path = [[NSBundle bundleForClass: [self class]] pathForResource: @"QCXExporter" ofType: @"plist"];
    NSData *data = [[NSData alloc] initWithContentsOfFile: path];
    NSError *error = nil;
    QCXExporter_Info = [[NSPropertyListSerialization propertyListWithData: data
                                                                  options: NSPropertyListImmutable
                                                                   format: NULL
                                                                    error: &error] retain];
    [data release];
  }
  return QCXExporter_Info;
}

+ (NSDictionary*) attributes {
	return [self plugInInfo];
}

// Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
+ (NSDictionary *) attributesForPropertyPortWithKey:(NSString *) key {
  return [[[self plugInInfo] objectForKey: @"attributes"] objectForKey: key];
}

// Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
+ (QCPlugInExecutionMode) executionMode {
	return kQCPlugInExecutionModeConsumer;
}

// Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
+ (QCPlugInTimeMode) timeMode {
	return kQCPlugInTimeModeNone;
}

// 	Release any non garbage collected resources created in -init.
- (void) finalize {
	[super finalize];
}

// Release any resources created in -init.
- (void) dealloc {
  //[recording release];
	//[rawImageDataArray release];
	[super dealloc];
}

// Return a list of the KVC keys corresponding to the internal settings of the plug-in.
//+ (NSArray *) plugInKeys {
//	return nil;
//}

// Provide custom serialization for the plug-in internal settings that are not values complying to the <NSCoding> protocol.
// The return object must be nil or a PList compatible i.e. NSString, NSNumber, NSDate, NSData, NSArray or NSDictionary.
//- (id) serializedValueForKey: (NSString *) key; {
//	return [super serializedValueForKey: key];
//}

// Provide deserialization for the plug-in internal settings that were custom serialized in -serializedValueForKey.
// Deserialize the value, then call [self setValue:value forKey:key] to set the corresponding internal setting of the plug-in instance to that deserialized value.
//- (void) setSerializedValue:(id)serializedValue forKey:(NSString*)key {
//	[super setSerializedValue:serializedValue forKey:key];
//}

- (QCPlugInViewController *) createViewController {
	return [[QCXExporterSettings alloc] initWithPlugIn: self viewNibName: @"QCXExporterSettings"];
}

- (void) save {
  switch (self.state) {
    case kQCXExporterStateIdle:
      return;
      break;
      
    case kQCXExporterStateRecording:
      return;
      break;
      
    case kQCXExporterStateSaving:
      break;
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  //controller.totalFrames = [rawImageDataArray count];
  //[controller showWindow: nil];
  
  //NSLog(@" * will write %i frames, time scale %f", [rawImageDataArray count], timeScale);
  // TODO: sort this array
  while (self.threadCount) {
    //NSLog(@" * waiting for threads...");
    [NSThread sleepForTimeInterval: 0.5];
  }
  NSUInteger currentFrame = 0;
  for (NSDictionary *e in rawImageDataArray) {
    
    // Check if paused
    while (isExportingPaused) {
      [NSThread sleepForTimeInterval: 0.5];
    }
    
    // Stopped or cancelled?
    if (isExportingStopped || isExportingCancelled) {
      break;
    }
    
    NSImage *image = [e objectForKey: @"image"];
    NSTimeInterval at = (NSTimeInterval)[(NSNumber *)[e objectForKey: @"at"] doubleValue];
    double timeScale = [(NSNumber *)[e objectForKey: @"timeScale"] doubleValue];
    //NSLog(@" * adding at %f ts %f", at, timeScale);
    [self addNSImageAsMPEG4: image at: at timeScale: timeScale];
    //controller.currentFrame = currentFrame;
    currentFrame++;
  }
  
  NSString *path = @"~/Movies/export-to-movie.mov";
  
  if (isExportingCancelled == NO)
    [self flattenToFile: [path stringByExpandingTildeInPath]];

  //[controller release];
  [pool drain];

  // TODO: move our of here
  [rawImageDataArray release];
  //[recording release];
  
  self.state = kQCXExporterStateIdle;
}

// Capture, compression inside, locks buffers
// Params are, qcImage and timeScale
- (BOOL) captureWithParams: (NSDictionary *) params {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  self.threadCount++;

  id<QCPlugInInputImageSource> qcImage = [params objectForKey: @"qcImage"];
  
  NSImage *nsImage = [self nsImageWithQCImage: qcImage convertToTIFF: YES lockBuffer: YES unlockBuffer: YES];
  
  NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
  
  [rawImageDataArray addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                                 nsImage, @"image",
                                 [NSNumber numberWithDouble: (double)now], @"at",
                                 [params objectForKey: @"timeScale"], @"timeScale",
                                 nil
                                 ]];
  
  if (((int)now) % 2 == secondSwap) {
    fps++;
  } else {
    //printf("%i\n", (int)fps);
    self.lastSecondFps = fps;
    fps = 0;
  }
  secondSwap = ((int)now) % 2;
  
  self.threadCount--;
  
  [pool drain];
  
  return YES;
}

// Capture, no compression inside
- (BOOL) captureWithNSImage: (NSImage *) nsImage {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
  
  [rawImageDataArray addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                                 nsImage, @"image",
                                 [NSNumber numberWithDouble: (double)now], @"at",
                                 nil
                                 ]];
  
  if (((int)now) % 2 == secondSwap) {
    fps++;
  } else {
    printf("%i\n", (int)fps);
    fps = 0;
  }
  secondSwap = ((int)now) % 2;

  [pool drain];
  
  return YES;
}

- (NSString *) pixelFormatWithColorSpace: (CGColorSpaceRef) colorSpace {
  if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
    return QCPlugInPixelFormatI8;
  else if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB)
#if __BIG_ENDIAN__
    return QCPlugInPixelFormatARGB8;
#else
    return QCPlugInPixelFormatBGRA8;
#endif
  else
    return nil;  
}

- (NSString *) recordingTime {
  if (lastCaptureAt > 1) {
    //NSDate *time = [[NSDate alloc] initWithTimeIntervalSinceNow: -sampleTakenAt];
    //NSTimeFormatString *timeFormat = [[NSTimeFormatString alloc] init]
    //return [NSString stringWithFormat: @"%02i:%02:%02"]
    return @"hh:mm:ss";
  } else {
    return @"--:--:--";
  }

}

- (NSString *) sampleInfo {
  if (lastCaptureAt > 1) {
    return [NSString stringWithFormat:
            @"%ix%i %@",
            sampleBufferPixelsWide,
            sampleBufferPixelsHigh,
            sampleBufferPixelFormat];
  } else {
    return @"-";
  }
}

- (BOOL) takeSampleWithQCImage: (id<QCPlugInInputImageSource>) image {
  [self willChangeValueForKey: @"sampleInfo"];
  
  CGColorSpaceRef colorSpace = [image imageColorSpace];
  NSString *pixelFormat = [self pixelFormatWithColorSpace: colorSpace];
  if (![image lockBufferRepresentationWithPixelFormat: pixelFormat colorSpace: colorSpace forBounds: [image imageBounds]])
    return NO;
  
  // Dimensions are KVC for UI
//  self.sampleBufferPixelsWide = [image bufferPixelsWide];
//  self.sampleBufferPixelsHigh = [image bufferPixelsHigh];
  
  sampleBufferBytesPerRow = [image bufferBytesPerRow];
  sampleBufferBaseAddress = [image bufferBaseAddress];
  sampleBufferPixelFormat = [[image bufferPixelFormat] copy];
  sampleImageBounds = [image imageBounds];
  //sampleImageColorSpace = malloc(sizeof(CGColorSpaceRef));
  //memcpy(sampleImageBounds, [image imageColorSpace], 1 * sizeof(CGColorSpaceRef));
  
  //NSLog(@" * sample taken %@", image);
  
  [image unlockBufferRepresentation];
  
  frame++;
  
  lastCaptureAt = [NSDate timeIntervalSinceReferenceDate];
  
  [self didChangeValueForKey: @"sampleInfo"];
  return YES;
}

- (NSImage *) nsImageWithQCImage: (id<QCPlugInInputImageSource>) qcImage convertToTIFF: (BOOL) convertToTIFF lockBuffer: (BOOL) lockBuffer unlockBuffer: (BOOL) unlockBuffer {
  CGColorSpaceRef colorSpace = [qcImage imageColorSpace];
  NSString *pixelFormat = [self pixelFormatWithColorSpace: colorSpace];
  
  // Get a buffer representation from the image in its native colorspace
  if (lockBuffer)
    if (![qcImage lockBufferRepresentationWithPixelFormat: pixelFormat colorSpace: colorSpace forBounds: [qcImage imageBounds]])
      return nil;
  
  CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL,
                                                                [qcImage bufferBaseAddress],
                                                                [qcImage bufferPixelsHigh] * [qcImage bufferBytesPerRow],
                                                                NULL);

  CGImageRef cgImage = CGImageCreate([qcImage bufferPixelsWide],
                                     [qcImage bufferPixelsHigh],
                                     8,
                                     (pixelFormat == QCPlugInPixelFormatI8 ? 8 : 32),
                                     [qcImage bufferBytesPerRow],
                                     colorSpace,
                                     (pixelFormat == QCPlugInPixelFormatI8 ? 0 : kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host),
                                     dataProvider,
                                     NULL,
                                     false,
                                     kCGRenderingIntentDefault);
  
  CGDataProviderRelease(dataProvider);
  
  if (cgImage == NULL) {
    if (unlockBuffer)
      [qcImage unlockBufferRepresentation];
    return nil;
  }
  
  NSImage *nsImage = [NSImage alloc];
  if (convertToTIFF) {
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage: cgImage];
    if (bitmapRep == NULL) {
      if (unlockBuffer)
        [qcImage unlockBufferRepresentation];
      return nil;
    }
    NSData *tiff = [bitmapRep TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: 0.0];
    nsImage = [nsImage initWithData: tiff];
    [bitmapRep release];
  } else {
    nsImage = [nsImage initWithCGImage: cgImage size: [qcImage imageBounds].size];
  }

  CGImageRelease(cgImage);
  
  // LOOK OUT: we're releasing lock as soon as we're not working on the same memory
  if (unlockBuffer)
    [qcImage unlockBufferRepresentation];
  
  return nsImage;
}

#pragma mark Recording

- (void) addNSImageAsMPEG4: (NSImage *) image {
  NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
  if (lastImageAddedAt < 1.0) // first frame
    lastImageAddedAt = now;
  NSTimeInterval timeDifference = now - lastImageAddedAt;
  //if (timeDifference > (100.0 / 2997.0)) {
  QTTime qtTime = QTMakeTime((long long)(timeDifference * 100 * 100), 100 * 100);
  [movie addImage: image // HACK: we dont use last image as we don't want to copy it
      forDuration: qtTime
   withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: @"mpv4", QTAddImageCodecType, nil]];
  [movie setCurrentTime: [movie duration]];
  //[lastImage release];
  lastImageAddedAt = now;
  //NSLog(@"+ last image at %.2f, now %.2f, interval %.2f, QTTime(%i, %i)", lastImageAddedAt, now, timeDifference, (int)qtTime.timeValue, (int)qtTime.timeScale);
  //} else {
  //NSLog(@"- time diff %f", timeDifference);
  //}
  //lastImage = [image copy];
}

- (void) addNSImageAsMPEG4: (NSImage *) image at: (NSTimeInterval) at timeScale: (double) timeScale {
  if (lastImageAddedAt < 1.0) // first frame
    lastImageAddedAt = at;
  NSTimeInterval timeDifference = at - lastImageAddedAt;
  NSLog(@" * adding image with time scale %f", timeScale);
  QTTime qtTime = QTMakeTime((long long)(timeScale * timeDifference * 100 * 100), (long)(100 * 100));
  [movie addImage: image // HACK: we dont use last image as we don't want to copy it
      forDuration: qtTime
   withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                    @"mp4v", QTAddImageCodecType,
                    [NSNumber numberWithInt: codecHighQuality], QTAddImageCodecQuality,
                    nil]];
  [movie setCurrentTime: [movie duration]];
  //[lastImage release];
  lastImageAddedAt = at;
  //NSLog(@"+ last image at %.2f, now %.2f, interval %.2f, QTTime(%i, %i)", lastImageAddedAt, at, timeDifference, (int)qtTime.timeValue, (int)qtTime.timeScale);
  //lastImage = [image copy];
}

- (BOOL) flattenToFile: (NSString *) path {
  return [self flattenToFile: path error: nil];
}

- (BOOL) flattenToFile: (NSString *) path error: (NSError **) error {
	BOOL success = NO;
	if (!path)
		goto bail;
  NSFileManager *defaultFileManager = [NSFileManager defaultManager];
  if ([defaultFileManager fileExistsAtPath: path])
    if (![defaultFileManager removeItemAtPath: path error: nil])
      goto bail;
	NSDictionary *dict = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: QTMovieFlatten];
	if (dict)
		success = [movie writeToFile: path withAttributes: dict error: error];
bail:
  NSLog(@"flattening %i", success);
	return success;
}

#pragma mark IB Actions

- (void) startRecording {
  NSLog(@"startRecording %i", self.state);
  switch (self.state) {
    case kQCXExporterStateIdle:
      // TODO: dealloc old movie and arrays
      //recording = [[QCXRecording alloc] initWithDelegate: self];
      rawImageDataArray = [[[NSMutableArray alloc] init] retain];
      rawQueue = [[[NSMutableArray alloc] init] retain];
      
      // Set frame for sampling stage
      // TODO: do we need it? Remove it?
      frame = -1;
      self.state = kQCXExporterStateRecording;
      break;
      
    case kQCXExporterStateRecording:
      return;
      break;
      
    case kQCXExporterStateSaving:
      return;
      break;
  }
}

- (void) stopRecording {
  switch (self.state) {
    case kQCXExporterStateIdle:
      return;
      break;
      
    case kQCXExporterStateRecording:
      self.state = kQCXExporterStateSaving;
      [[[NSThread alloc] initWithTarget: self selector: @selector(save) object: nil] start];
      break;
      
    case kQCXExporterStateSaving:
      return;
      break;
  }
}

- (void) pauseExporting {
  self.isExportingPaused = YES;
}

- (void) resumeExporting {
  self.isExportingPaused = NO;
}

- (void) finishExporting {
  self.isExportingStopped = YES;
}

- (void) cancelExporting {
  self.isExportingCancelled = YES;
}

@end

#pragma mark Execution

@implementation QCXExporter (Execution)

// Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
// Return NO in case of fatal failure (this will prevent rendering of the composition to start).
- (BOOL) startExecution:(id<QCPlugInContext>)context {
	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>) context {
}

// Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
- (void) enableExecution: (id<QCPlugInContext>) context {
  data = [[NSMutableData alloc] init];
  movie = [[QTMovie alloc] initToWritableData: data error: nil];
}

// Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
- (void) disableExecution:(id<QCPlugInContext>) context {
  [data release];
  [movie release];
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
  
  //NSLog(@" * in execute with state %i", self.state);
  
  switch (self.state) {
    case kQCXExporterStateIdle:
      if ([self didValueForInputKeyChange: @"inputRecord"] && self.inputRecord == YES) {
        [self startRecording];
      } else {
        return YES;
      }
      break;
      
    case kQCXExporterStateRecording:
      if ([self didValueForInputKeyChange: @"inputRecord"] && self.inputRecord == NO) {
        [self stopRecording];
        return YES;
      }
      break;

    case kQCXExporterStateSaving:
      return YES;
      break;
  }
  
  // Make sure we've got something new
  if(![self didValueForInputKeyChange: @"inputImage"])
    return YES;
  
  // Make sure we've got an image
  id<QCPlugInInputImageSource> qcImage = self.inputImage;
  if (!qcImage)
    return YES;

  // Sampling, make sure there is an image with dimentions inside
  if (frame < 0) {
    return [self takeSampleWithQCImage: qcImage];
  }
  
  //NSImage *nsImage = [self nsImageWithQCImage: qcImage convertToTIFF: NO lockBuffer: YES unlockBuffer: YES];

// HACK: overcome buffer locking
// size_t l = sampleBufferBytesPerRow * sampleBufferPixelsHigh;
// void *tmp = malloc(l);
// memcpy(tmp, sampleBufferBaseAddress, l);
// NSData *tmpData = [NSData dataWithBytesNoCopy: tmp length: l freeWhenDone: YES];
  
  // Run in background
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          qcImage, @"qcImage",
                          [NSNumber numberWithDouble: self.inputTimeScale], @"timeScale",
                          nil
                          ];

  [[[NSThread alloc] initWithTarget: self selector: @selector(captureWithParams:) object: params] start];
  
  // Run in this thread
  //return [self captureWithNSImage: nsImage];
  
	return YES;
}

@end
