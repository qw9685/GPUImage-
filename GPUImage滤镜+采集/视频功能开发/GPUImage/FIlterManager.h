//
//  FIlterManager.h
//  视频功能开发
//
//  Created by mac on 2019/7/23.
//  Copyright © 2019 cc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface FIlterManager : NSObject

- (GPUImageFilter*)addFilter_Sketch;//素描

- (GPUImageFilterGroup*)addFilter_Beautify;//美颜

- (GPUImageFilter*)addFilter_Gamma;//伽马线

- (GPUImageFilter*)addFilter_ColorInvert;//反色

- (GPUImageFilter*)addFilter_Sepia;//褐色（怀旧）

- (GPUImageFilter*)addFilter_Grayscale;//灰度

- (GPUImageFilter*)addFilter_HistogramGenerator;//色彩直方图

- (GPUImageFilter*)addFilter_RGB;//RGB颜色

- (GPUImageFilter*)addFilter_Monochrome;//单色

- (GPUImageFilter*)addFilter_SobelEdgeDetection;//Sobel边缘检测算法(白边，黑内容，有点漫画的反色效果)

- (GPUImageFilter*)addFilter_XYDerivative;//XYDerivative边缘检测，画面以蓝色为主，绿色为边缘，带彩色

- (GPUImageFilterGroup*)addFilter_SmoothToon;//漫画

- (GPUImageFilter*)addFilter_ColorPacking;//监控

@end

NS_ASSUME_NONNULL_END
