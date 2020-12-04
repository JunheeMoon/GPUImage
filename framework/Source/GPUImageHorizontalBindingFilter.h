#import "GPUImageFilterGroup.h"


@class GPUImageGrayscaleFilter;
@class GPUImageAdaptiveThresholdFilter2;
@class GPUImageBoxBlurFilter;
@class GPUImageSobelEdgeDetectionFilter;
@class GPUImageMotionBlurFilter;
@class GPUImageColorInvertFilter;
@class GPUImageOpeningFilter;
@class GPUImageClosingFilter;
@class GPUImageColorInvertFilter;


/** This applies the simple letter detection process for test FindCountourDetector
 */
@interface GPUImageHorizontalBindingFilter : GPUImageFilterGroup
{
     
    GPUImageFilter *gray_filter;
    
    GPUImageAdaptiveThresholdFilter2 *threshold_filter;
    GPUImageBoxBlurFilter *blur_filter;
    GPUImageSobelEdgeDetectionFilter * sobelFilter;
    
    GPUImageMotionBlurFilter *m_blur_filter;
    GPUImageMotionBlurFilter *m_blur_filter2;
    GPUImageMotionBlurFilter *m_blur_filter3;
    GPUImageColorInvertFilter *cv_filter2; 
    
    GPUImageClosingFilter *closingFilter;
    GPUImageAdaptiveThresholdFilter2 *threshold_filter3;
    GPUImageOpeningFilter *openingFilter;
    GPUImageColorInvertFilter *cv_filter;
      
}
 
@end
