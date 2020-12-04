#import "GPUImageFilterGroup.h"

@interface GPUImageAdaptiveThresholdFilter2 : GPUImageFilterGroup

/** A multiplier for the background averaging blur radius in pixels, with a default of 4
 */

/**
 Just only one is changed from  GPUImageAdaptiveThresholdFilter
 - (id)init:(NSString *)thr;  >>>> thr parameter is added.  for adjust thresholdResult manually.
 */
@property(readwrite, nonatomic) CGFloat blurRadiusInPixels;
- (id)init:(NSString *)thr; 
@end
