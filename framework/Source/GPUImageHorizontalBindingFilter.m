#import "GPUImageHorizontalBindingFilter.h"

#import "GPUImageGrayscaleFilter.h"  
#import "GPUImageAdaptiveThresholdFilter2.h"
#import "GPUImageBoxBlurFilter.h"
#import "GPUImageSobelEdgeDetectionFilter.h"
#import "GPUImageMotionBlurFilter.h"
#import "GPUImageColorInvertFilter.h"
#import "GPUImageClosingFilter.h"
#import "GPUImageOpeningFilter.h"
#import "GPUImageColorInvertFilter.h"
@implementation GPUImageHorizontalBindingFilter
 

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    } 
    
    // First pass: convert image to gray
   gray_filter=[[GPUImageGrayscaleFilter alloc]init];
   [self addFilter:gray_filter];
    
    // Second pass: apply adaptive threshold filter for make image simple
    threshold_filter=[[GPUImageAdaptiveThresholdFilter2 alloc]init:@"0.12"];
   [self addFilter:threshold_filter];
     
    // Third pass: blurring
   blur_filter=[[GPUImageBoxBlurFilter alloc]init];
   blur_filter.texelSpacingMultiplier=0.2;
   [self addFilter:blur_filter];
   
    // Fourth pass :run the Sobel edge detection.
    sobelFilter=[[GPUImageSobelEdgeDetectionFilter alloc]init];
    [self addFilter:sobelFilter];
    
    // 6-th pass : blurring for horizontal spread
    m_blur_filter=[[GPUImageMotionBlurFilter alloc]init];
    m_blur_filter.blurSize=1.1;
    m_blur_filter.blurAngle=20;
      
    m_blur_filter2=[[GPUImageMotionBlurFilter alloc]init];
    m_blur_filter2.blurSize=1.1;
    m_blur_filter2.blurAngle=160;
           
    m_blur_filter3=[[GPUImageMotionBlurFilter alloc]init];
    m_blur_filter3.blurSize=1.12;
    m_blur_filter3.blurAngle=90;
    [self addFilter:m_blur_filter];
    [self addFilter:m_blur_filter2];
    [self addFilter:m_blur_filter3];
    
    // 7th pass : color inverting before closing filter
    cv_filter2=[[GPUImageColorInvertFilter alloc]init];
    [self addFilter:cv_filter2];
   
    // 8th pass : closing and openging pass. for remove particle and merging near letters
    closingFilter=[[GPUImageClosingFilter alloc]init];
    [closingFilter setVerticalTexelSpacing:1];
    [closingFilter setHorizontalTexelSpacing:1];
    [self addFilter:closingFilter];
    openingFilter=[[GPUImageOpeningFilter alloc]init];
    [openingFilter setVerticalTexelSpacing:1];
    [openingFilter setHorizontalTexelSpacing:1];
    [self addFilter:openingFilter];

    // 9th pass : apply one more adaptiveThreashhold filter
    threshold_filter3=[[GPUImageAdaptiveThresholdFilter2 alloc]init:@"0.03"];
    [self addFilter:threshold_filter3];
    
    //cv_filter=[[GPUImageColorInvertFilter alloc]init];
    //[self addFilter:cv_filter];
    
    [gray_filter     addTarget:threshold_filter];
    [threshold_filter  addTarget:blur_filter];
    [blur_filter    addTarget:sobelFilter]; 
    [sobelFilter     addTarget:m_blur_filter];
    [m_blur_filter  addTarget:m_blur_filter2];
    [m_blur_filter2 addTarget:m_blur_filter3];
    [m_blur_filter3   addTarget:cv_filter2];
    [cv_filter2     addTarget:closingFilter];
    [closingFilter  addTarget:openingFilter];
    [openingFilter addTarget:threshold_filter3];
    
    
    self.initialFilters = [NSArray arrayWithObject:gray_filter];
//    self.terminalFilter = nonMaximumSuppressionFilter;
    self.terminalFilter = threshold_filter3;
     
    
    return self;
}

#pragma mark -
#pragma mark Accessors
 
@end
