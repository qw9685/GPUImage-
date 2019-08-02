//
//  CCGPUImageRawDataOutput.h
//  视频功能开发
//
//  Created by mac on 2019/7/24.
//  Copyright © 2019 cc. All rights reserved.
//

#import "GPUImageRawDataOutput.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CCGPUImageRawDataOutputDelegate <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime andSize:(CGSize)imageSize andData:(uint8_t *)rawBytesForImage;
@end

@interface CCGPUImageRawDataOutput : GPUImageRawDataOutput<CCGPUImageRawDataOutputDelegate>

@property (nonatomic,weak)id <CCGPUImageRawDataOutputDelegate> dataDelegate;

@end


NS_ASSUME_NONNULL_END
