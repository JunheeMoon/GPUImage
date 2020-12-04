#import "GPUImageFilter.h"

@interface GPUImageQuadGenerator : GPUImageFilter
{
    GLint quadWidthUniform, quadColorUniform;
    GLfloat *quadCoordinates;
}

// The width of the displayed quads, in pixels. The default is 1.
@property(readwrite, nonatomic) CGFloat quadWidth;

// The color of the quads is specified using individual red, green, and blue components (normalized to 1.0). The default is green: (0.0, 1.0, 0.0).
- (void)setQuadColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;

// Rendering
- (void)renderQuadsFromArray:(GLfloat *)quadSlopeAndIntercepts count:(NSUInteger)numberOfQuads frameTime:(CMTime)frameTime;

@end 
