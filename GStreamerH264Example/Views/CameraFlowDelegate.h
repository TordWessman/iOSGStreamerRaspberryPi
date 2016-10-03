//
//  CameraFlowDelegate.h
//  GstreamerLiveStream
//
//  Created by Tord Wessman on 18/08/15.
//  Copyright (c) 2015 Axel IT AB. All rights reserved.
//

#import "CameraView.h"

#include <gst/app/gstappsink.h>
#include <gst/video/video.h>
#import <UIKit/UIKit.h>
#include <gst/app/gstappsink.h>

@interface CameraView () {
    
}

// Tells us if we are still looking for the parameter set (contains information that an h.264 decoder needs to decode the video data, for example the resolution and frame rate of the video.)
@property(readwrite) BOOL searchForSPSAndPPS;
@property(readwrite) NSData * spsData;
@property(readwrite) NSData * ppsData;
@property(readwrite) AVSampleBufferDisplayLayer* displayLayer;
@property(readwrite) dispatch_queue_t queue;
@property(readwrite) GstElement* pipeline;
@property(readwrite) GstElement* appsink;
@property(readwrite) GMainLoop* loop;
@property(readwrite) CMVideoFormatDescriptionRef videoFormatDescr;
@property(readwrite) BOOL willSleep;

// Tells us if we have the first key frame
@property(readwrite) BOOL gotFirstIDR;

@end

GST_DEBUG_CATEGORY_STATIC (debug_category);
#define GST_CAT_DEFAULT debug_category

NSString * const naluTypesStrings[] = {
    @"Unspecified (non-VCL)",
    @"Coded slice of a non-IDR picture (VCL)",
    @"Coded slice data partition A (VCL)",
    @"Coded slice data partition B (VCL)",
    @"Coded slice data partition C (VCL)",
    @"Coded slice of an IDR picture (VCL)",
    @"Supplemental enhancement information (SEI) (non-VCL)",
    @"Sequence parameter set (non-VCL)",
    @"Picture parameter set (non-VCL)",
    @"Access unit delimiter (non-VCL)",
    @"End of sequence (non-VCL)",
    @"End of stream (non-VCL)",
    @"Filler data (non-VCL)",
    @"Sequence parameter set extension (non-VCL)",
    @"Prefix NAL unit (non-VCL)",
    @"Subset sequence parameter set (non-VCL)",
    @"Reserved (non-VCL)",
    @"Reserved (non-VCL)",
    @"Reserved (non-VCL)",
    @"Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
    @"Coded slice extension (non-VCL)",
    @"Coded slice extension for depth view components (non-VCL)",
    @"Reserved (non-VCL)",
    @"Reserved (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
};

static GstFlowReturn new_sample(GstAppSink *sink, gpointer user_data)
{
    
    CameraView *backend = (__bridge CameraView *)(user_data);
    
    if (backend.displayLayer.error != nil) {
        
        NSLog(@"Error: %@, Status:%@", backend.displayLayer.error, (backend.displayLayer.status == AVQueuedSampleBufferRenderingStatusUnknown)?@"unknown":((backend.displayLayer.status == AVQueuedSampleBufferRenderingStatusRendering)?@"rendering":@"failed"));
        
        return GST_FLOW_FLUSHING;
        
    }
    
    GstSample *sample = gst_app_sink_pull_sample(sink);
    GstBuffer *buffer = gst_sample_get_buffer(sample);
    GstMemory *memory = gst_buffer_get_all_memory(buffer);
    
    GstMapInfo info;
    gst_memory_map (memory, &info, GST_MAP_READ);
    
    int startCodeIndex = 0;
    
    for (int i = 0; i < 5; i++) {
        
        if (info.data[i] == 0x01) {
            
            startCodeIndex = i;
            break;
            
        }
        
    }
    
    int nalu_type = ((uint8_t)info.data[startCodeIndex + 1] & 0x1F);
    
    //NSLog(@"NEW SAMPLE, type: %i", nalu_type);
    
    if(backend.searchForSPSAndPPS) {
        
        backend.gotFirstIDR = NO;
        
        if (nalu_type == 7) {
            
            backend.spsData = [NSData dataWithBytes:&(info.data[startCodeIndex + 1]) length: info.size - 4];
            
        }
        
        if (nalu_type == 8) {
            
            backend.ppsData = [NSData dataWithBytes:&(info.data[startCodeIndex + 1]) length: info.size - 4];
            
        }
        
        if (backend.spsData != nil && backend.ppsData != nil) {
            
            const uint8_t* const parameterSetPointers[2] = { (const uint8_t*)[backend.spsData bytes], (const uint8_t*)[backend.ppsData bytes] };
            const size_t parameterSetSizes[2] = { [backend.spsData length], [backend.ppsData length] };
            
            CMVideoFormatDescriptionRef videoFormatDescr;
            OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &videoFormatDescr);
            [backend setVideoFormatDescr:videoFormatDescr];
            
            [backend setSearchForSPSAndPPS:false];
            
            NSLog(@"Found all data for CMVideoFormatDescription. Creation: %@.", (status == noErr) ? @"successfully." : @"failed.");
            
        }
        
    }
    
    if (!backend.searchForSPSAndPPS && (nalu_type == 1 || nalu_type == 5)) {
        
        CMBlockBufferRef videoBlock = NULL;
        
        OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL, info.data, info.size, kCFAllocatorNull, NULL, 0, info.size, 0, &videoBlock);
        
        if((status != kCMBlockBufferNoErr)) {
            
            NSLog(@"BlockBufferCreation: %@ size: %lu", (status == kCMBlockBufferNoErr) ? @"successfully." : @"failed.", info.size);
            
        }
        
        info.size = info.size - 4;
        
        const uint8_t sourceBytes[] = {(uint8_t)(info.size >> 24), (uint8_t)(info.size >> 16), (uint8_t)(info.size >> 8), (uint8_t)info.size};
        status = CMBlockBufferReplaceDataBytes(sourceBytes, videoBlock, 0, 4);
        
        if((status != kCMBlockBufferNoErr)) {
            
            NSLog(@"BlockBufferReplace: %@", (status == kCMBlockBufferNoErr) ? @"successfully." : @"failed.");
            
        }
        
        CMSampleBufferRef sbRef = NULL;
        const size_t sampleSizeArray[] = {info.size};
        
        status = CMSampleBufferCreate(kCFAllocatorDefault, videoBlock, true, NULL, NULL, backend.videoFormatDescr, 1, 0, NULL, 1, sampleSizeArray, &sbRef);
        
        if((status != kCMBlockBufferNoErr)) {
            
            NSLog(@"SampleBufferCreate: %@", (status == noErr) ? @"successfully." : @"failed.");
            
        }
        
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sbRef, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        
        if (!backend.willSleep) {
            
            dispatch_async(dispatch_get_main_queue(),^{
                
                if (sbRef && backend.displayLayer && backend.displayLayer.isReadyForMoreMediaData) {
                    
                    [backend.displayLayer enqueueSampleBuffer:sbRef];
                    [backend.displayLayer setNeedsDisplay];
                    
                    if (nalu_type == 5 && !backend.gotFirstIDR) {
                        
                        backend.gotFirstIDR = YES;
                        
                        if (backend.delegate && [backend.delegate respondsToSelector:@selector(doneBuffering)]) {
                            
                            [backend.delegate doneBuffering];
                            
                        }
                        
                    }
                    
                }
                
            });
            
        }
        
    } else if ( (nalu_type != 7 && nalu_type != 8) && (nalu_type != 1 && nalu_type != 5)) {
        
        NSLog(@"Unhandeled NALU with Type %i, \"%@\" received: %lu.",nalu_type,  naluTypesStrings[nalu_type], info.size);
        
    }
    
    gst_memory_unmap(memory, &info);
    gst_memory_unref(memory);
    gst_buffer_unref(buffer);
    
    return GST_FLOW_OK;
    
}
