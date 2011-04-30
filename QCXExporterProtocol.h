//
//  QCXRecordingProtocol.h
//  Exporter
//
//  Created by Mirek Rusin on 21/12/2010.
//  Copyright 2010 Inteliv Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol QCXExporterProtocol <NSObject>

- (void) didStartRecordingForExporter: (QCXExporter *) exporter;
- (void) didBeginSavingForExporter: (QCXExporter *) exporter;
- (void) didFinishSavingForExporter: (QCXExporter *) exporter;

@end
