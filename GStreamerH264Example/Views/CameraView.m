//
//  CameraView.m
//  GstreamerLiveStream
//
//  Created by Tord Wessman on 17/08/15.
//  Copyright (c) 2015 Axel IT AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraView.h"
#import "CameraFlowDelegate.h"

#include <gst/video/video.h>

@interface CameraView () {
    
    NSString * m_host;
    NSInteger m_port;
    BOOL m_isRunning;

    
    id<CameraViewDelegate> m_delegate;
    id<CameraViewTouch> m_touchDelegate;
    
}


@end

@implementation CameraView

- (void) setup: (NSString *) host port:(NSInteger) port {
    
    m_port = port;
    m_host = host;
    
    self.searchForSPSAndPPS = true;
    self.ppsData = nil;
    self.spsData = nil;
    self.displayLayer = [[AVSampleBufferDisplayLayer alloc] init];

    self.displayLayer.backgroundColor = [UIColor blackColor].CGColor;

    self.displayLayer.bounds = self.layer.bounds;
    self.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds) + 5, CGRectGetMidY(self.bounds));
    
    self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   
    dispatch_async(self.queue, ^{
        
        [self setUpPipeline];
        [self app_function:NO];
        
    });
    
    [self.layer addSublayer: self.displayLayer];
    
}

- (void)start
{
    
    self.willSleep = NO;
    
    if (self.searchForSPSAndPPS) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(beginBuffering)]) {
            
            [self.delegate beginBuffering];
        
        }
    
    }
   
    if (!m_isRunning) {
        
            [self.displayLayer flushAndRemoveImage];
        
        dispatch_async(self.queue, ^{
            
            [self app_function:YES];
            
        });
        
    } else {
        
        if(gst_element_set_state(self.pipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(gotError:)]) {
                
                [self.delegate gotError: @"Failed to start"];
                
            }
            
        }
        
    }

}

-(void) pause
{
    self.willSleep = YES;
    
    if(gst_element_set_state(self.pipeline, GST_STATE_PAUSED) == GST_STATE_CHANGE_FAILURE) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(gotError:)]) {
            
            [self.delegate gotError: @"Failed to pause"];
            
        }
        
    }
    
}

-(void) reset
{
    self.willSleep = YES;
    
    if(gst_element_set_state(self.pipeline, GST_STATE_NULL) == GST_STATE_CHANGE_FAILURE) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(gotError:)]) {
            
            NSLog(@"Failed to reset");
            [self.delegate gotError: @"Failed to reset"];
            
        }

    }
    
    [self.displayLayer flushAndRemoveImage];

    self.searchForSPSAndPPS = true;
    self.ppsData = nil;
    self.spsData = nil;
    
    
}

- (void) setDelegate:(id<CameraViewDelegate>) delegate {
    
    m_delegate = delegate;

}

- (void) setTouch:(id<CameraViewTouch>) delegate {

    m_touchDelegate = delegate;

}

- (id<CameraViewDelegate>) delegate {
    
    return m_delegate;

}

- (void) app_function: (BOOL)startPlaying
{
    
    GMainContext *context = g_main_context_new ();
    g_main_context_push_thread_default(context);
    g_set_application_name ("videoplayer");

    if(gst_element_set_state(self.pipeline, GST_STATE_READY) != GST_STATE_CHANGE_SUCCESS) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(gotError:)]) {
            
            [self.delegate gotError: @"could not change pipeline to ready"];
            NSLog(@"could not change pipeline to ready");
            
        }

    }
    
    m_isRunning = true;
    
    NSLog(@"Try to start");
    
    if (startPlaying) {
        
        NSLog(@"Ready");
        
        if(gst_element_set_state(self.pipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(gotError:)]) {
                
                [self.delegate gotError: @"Failed to start"];
                NSLog(@"Failed to start");
                
            }
            
        }
        
    }
    self.loop = g_main_loop_new (context, FALSE);

    g_main_loop_run (self.loop);
        
    /* Free resources */
    g_main_loop_unref (self.loop);
    self.loop = NULL;
    g_main_context_pop_thread_default(context);
    g_main_context_unref (context);
    m_isRunning = false;
    
//    gst_object_unref (GST_OBJECT (self.pipeline));
    
}

// Creates the pipeline for (re) use
- (void) setUpPipeline {
    
    GstElement *tcpsrc, *queue, *gdpdepay, *rtphdepay, *capsfilter;
    
    self.pipeline = gst_pipeline_new ("videopipe");
    
    tcpsrc = gst_element_factory_make ("tcpclientsrc", "tcpsrc");
    queue = gst_element_factory_make ("queue", "queue");
    gdpdepay = gst_element_factory_make ("gdpdepay", "gdpdepay");
    
    GstCaps *caps = gst_caps_new_simple("application/x-rtp", "media", G_TYPE_STRING, "video", "clock-rate", G_TYPE_INT, 90000, "encoding-name", G_TYPE_STRING, "H264", NULL);
    
    g_object_set(gdpdepay, "caps", caps, NULL);
    
    gst_caps_unref(caps);
    
    g_object_set(G_OBJECT(tcpsrc), "port", m_port, NULL);
    g_object_set(G_OBJECT(tcpsrc), "host", [m_host UTF8String], NULL);
    g_object_set(G_OBJECT(queue), "leaky", 1, NULL);
    g_object_set(G_OBJECT(queue), "max-size-buffers", "16", NULL);
    
    rtphdepay = gst_element_factory_make("rtph264depay", "rtph264depay"
                                         );
    capsfilter = gst_element_factory_make("capsfilter", "capsfilter");
    caps = gst_caps_new_simple("video/x-h264", "streamformat", G_TYPE_STRING, "byte-stream", "alignment", G_TYPE_STRING, "nal", NULL);
    //caps = gst_caps_new_simple("video/x-h264", "streamformat", G_TYPE_STRING, "avc", "alignment", G_TYPE_STRING, "nal", NULL);
    
    g_object_set(capsfilter, "caps", caps, NULL);
    self.appsink = gst_element_factory_make ("appsink", "appsink");
    
    NSLog(@"Initiating...");
    if (self.appsink == nil) {
        
        NSLog(@"ARGH! Unable to create Appsink");
        exit (1);
        
    } else if (rtphdepay == nil) {
        
        NSLog(@"ARGH! Unable to create rtph264depay");
        exit (1);
        
    }  else if (caps == nil || capsfilter == nil || queue == nil ) {
        
        NSLog(@"ARGH! Unable to create queue, caps or capsfilter");
        exit (1);
        
    } else  if (tcpsrc == nil) {
        
        NSLog(@"ARGH! Unable to create tcpserversrc");
        exit (1);
        
    } else  if (gdpdepay == nil) {
        
        NSLog(@"ARGH! Unable to create gdpdepay");
        exit (1);
    }
    
    gst_bin_add_many (GST_BIN (self.pipeline), tcpsrc, queue, gdpdepay, rtphdepay, capsfilter, self.appsink, NULL);
    
    if(!gst_element_link_many (tcpsrc, gdpdepay, queue, rtphdepay, capsfilter, self.appsink, NULL)) {
        
        NSLog(@"Cannot link gstreamer elements");
        exit (1);
        
    }
    
    GstAppSinkCallbacks callbacks = { NULL, NULL, new_sample,
        NULL, NULL};
    
    gst_app_sink_set_callbacks (GST_APP_SINK(self.appsink), &callbacks, (__bridge gpointer)(self), NULL);

}


-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *aTouch = [touches anyObject];
    CGPoint point = [aTouch locationInView:self];
    
    if (m_touchDelegate && [m_touchDelegate respondsToSelector:@selector(didTouch:dy:)]) {
        
        CGFloat dx =  (point.x - self.frame.size.width/2) / (self.frame.size.width/2);
        CGFloat dy =  (point.y - self.frame.size.height/2) / (self.frame.size.height/2);
        [m_touchDelegate didTouch: dx dy:dy];

    }

}



@end
