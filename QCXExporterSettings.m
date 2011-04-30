//
//  QCXExporterSettings.m
//  QCXExporter
//
//  Created by Mirek Rusin on 28/01/2010.
//  Copyright 2010 Inteliv Ltd. All rights reserved.
//

#import "QCXExporterSettings.h"

#define PlugIn ((QCXExporter *)self.plugIn)

@implementation QCXExporterSettings

@synthesize progressIndicator;
//@synthesize startedAt;
//@synthesize currentFrame;
//@synthesize totalFrames;
//@synthesize pause;
//@synthesize stopAndSave;
//@synthesize cancel;
//@synthesize plugIn;

//- (IBAction) save: (id) sender {
//  [(QCXExporter *)self.plugIn stopRecording: sender];
//}

- (void) setCurrentFrame: (NSUInteger) value {
  [self willChangeValueForKey:@"etaInSeconds"];
  [self willChangeValueForKey:@"currentFrame"];
//  if (self.startedAt < 1)
//    self.startedAt = self.now;
  currentFrame = value;
  [self didChangeValueForKey: @"currentFrame"];
  [self didChangeValueForKey: @"etaInSeconds"];
}

- (NSTimeInterval) now {
  return [NSDate timeIntervalSinceReferenceDate];
}

- (NSTimeInterval) timeSpent {
//  if (self.currentFrame == 0)
    return 0;
//  else 
//    return self.now - self.startedAt;
}

- (NSTimeInterval) totalTime {
//  if (self.currentFrame == 0)
    return 0;
//  else 
//    return (self.timeSpent / self.currentFrame) * totalFrames;
}

- (NSTimeInterval) eta {
//  if (self.currentFrame == 0)
    return 0;
//  else 
//    return self.totalTime - self.timeSpent;
}

- (int) etaInSeconds {
//  if (self.currentFrame == 0)
    return 0;
//  else 
//    return (int)self.eta;
}

#pragma mark IB Actions

- (IBAction) startRecording: (id) sender {
  [PlugIn startRecording];
}

- (IBAction) stopRecording: (id) sender {
  [PlugIn stopRecording];
}

- (IBAction) pauseExporting: (id) sender {
  [PlugIn pauseExporting];
}

- (IBAction) resumeExporting: (id) sender {
  [PlugIn resumeExporting];
}

- (IBAction) finishExporting: (id) sender {
  [PlugIn finishExporting];
}

- (IBAction) cancelExporting: (id) sender {
  [PlugIn cancelExporting];
}

@end
