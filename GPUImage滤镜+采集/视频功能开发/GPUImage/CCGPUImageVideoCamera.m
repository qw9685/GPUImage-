//
//  CCGPUImageVideoCamera.m
//  视频功能开发
//
//  Created by mac on 2019/7/24.
//  Copyright © 2019 cc. All rights reserved.
//

#import "CCGPUImageVideoCamera.h"

@implementation CCGPUImageVideoCamera

-(void)processAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    [super processAudioSampleBuffer:sampleBuffer];
    if (self.audioDelegate && [self.audioDelegate respondsToSelector:@selector(processAudioSample:)]) {
        [self.audioDelegate processAudioSample:sampleBuffer];
    }
}


@end
