//
//  CameraView.h
//  GstreamerLiveStream
//
//  Created by Tord Wessman on 17/08/15.
//  Copyright (c) 2015 Axel IT AB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include <gst/gst.h>
#import <CoreMedia/CoreMedia.h>
#import "PauseProtocol.h"

#ifndef GardenController_CameraView_h
#define GardenController_CameraView_h

@protocol CameraViewDelegate<NSObject>

@optional

- (void) beginBuffering;
- (void) doneBuffering;
- (void) gotError: (NSString *)message;

@end

@protocol CameraViewTouch<NSObject>

-(void) didTouch: (CGFloat)dx dy:(CGFloat)dy;

@end

@interface CameraView : UIView<PauseProtocol>{
    
}

@property (weak, readonly) id<CameraViewDelegate> delegate;

- (void) setup: (NSString *) host port:(NSInteger) port;
- (void) start;
- (void) pause;
- (void) reset;
- (void) setDelegate:(id<CameraViewDelegate>) delegate;
- (void) setTouch:(id<CameraViewTouch>) delegate;

@end

#endif
