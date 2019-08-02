//
//  CCGPUImageRawDataOutput.m
//  视频功能开发
//
//  Created by mac on 2019/7/24.
//  Copyright © 2019 cc. All rights reserved.
//

#import "CCGPUImageRawDataOutput.h"

@implementation CCGPUImageRawDataOutput

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat
{
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        
    }
    return self;
}

- (id)init{
    if (self = [super init]) {
    }
    return self;
}

-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    if (self.dataDelegate && [self.dataDelegate respondsToSelector:@selector(newFrameReadyAtTime:andSize:andData:)]) {
        [self lockFramebufferForReading];
        [self.dataDelegate newFrameReadyAtTime:frameTime andSize:imageSize andData:self.rawBytesForImage];
        [self unlockFramebufferAfterReading];
    }
}

@end
