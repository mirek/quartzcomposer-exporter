//
//  QCXExporterSettings.h
//  QCXExporter
//
//  Created by Mirek Rusin on 28/01/2010.
//  Copyright 2010 Inteliv Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "QCXExporter.h"

@interface QCXExporterSettings : QCPlugInViewController {
  NSProgressIndicator *progressIndicator;
  NSTimeInterval startedAt;
  NSUInteger currentFrame;
  NSUInteger totalFrames;
  BOOL pause;
}

@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction) startRecording: (id) sender;
- (IBAction) stopRecording: (id) sender;

- (IBAction) pauseExporting: (id) sender;
- (IBAction) finishExporting: (id) sender;
- (IBAction) cancelExporting: (id) sender;

@end
