//
//  CCGPUImageVideoCamera.h
//  视频功能开发
//
//  Created by mac on 2019/7/24.
//  Copyright © 2019 cc. All rights reserved.
//

#import "GPUImageVideoCamera.h"

NS_ASSUME_NONNULL_BEGIN
//取音频信息
@protocol CCGPUImageVideoCameraDelegate <NSObject>
-(void) processAudioSample:(CMSampleBufferRef)sampleBuffer;
@end

@interface CCGPUImageVideoCamera : GPUImageVideoCamera
@property (nonatomic, weak) id<CCGPUImageVideoCameraDelegate> audioDelegate;

@end

NS_ASSUME_NONNULL_END
