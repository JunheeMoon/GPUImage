#import "GPUImageFilterGroup.h"
#import "GPUImage.h"
// Simple Demo : https://github.com/JunheeMoon/iOS-Image-Processing-using-GPUImage-Framework

// This applies a Suzuki85 Algorithm (OpenCV's findcontour) to detect text object in a scene.
// This approach is based entirely on the Suzuki Algorithm below
//Suzuki, S., and Be, K. (1985). Topological structural analysis of digitized binary images by border following. Computer Vision, Graphics, and Image Processing 30, 32–46. doi:10.1016/0734-189X(85)90016-7.

/*
 Suzuki85 Algorithm for GPUImage IOS.
 
 The 3-Clause BSD License
 SPDX short identifier: BSD-3-Clause

 Note: This license has also been called the "New BSD License" or "Modified BSD License". See also
  the 2-clause BSD License.

 Copyright 2020 Junhee Moon

 Redistribution and use in source and binary forms, with or without modification, are permitted
  provided that the following conditions are met:
 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the
  following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
  and the following disclaimer in the documentation and/or other materials provided with the
  distribution.

 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
  or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
 */
 
// Some code lines of these (.h,.m) files are Referenced from : https://github.com/opencv/opencv/blob/master/modules/imgproc/src/contours.cpp

//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//                        Intel License Agreement
//                For Open Source Computer Vision Library
// Copyright (C) 2000, Intel Corporation, all rights reserved.
// Third party copyrights are property of their respective owners.
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of Intel Corporation may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage. 
  

typedef signed char schar;
@interface GPUImageFindContourDetector : GPUImageFilterGroup
{
      
    GPUImageColorInvertFilter *cv_filter;
      
    GLfloat *linesArray;
    GLbyte *rawImagePixels;
    GLbyte *rawImagePixels_temp;
}
+ (void) icvFetchContour : (GLbyte*) ptr stepV: (int) step ptxV: (int) ptx ptyV: (int) pty;


// This block is called on the detection of lines, usually on every processed frame. A C array containing normalized slopes and intercepts in m, b pairs (y=mx+b) is passed in, along with a count of the number of lines detected and the current timestamp of the video frame
 
// This block is called on the detection of new corner points, usually on every processed frame. A C array containing normalized coordinates in X, Y pairs is passed in, along with a count of the number of corners detected and the current timestamp of the video frame
@property(nonatomic, copy) void(^cornersDetectedBlock)(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime);

//This block is called on the detection of box's first and last point.
@property(nonatomic, copy) void(^boxesDetectedBlock)(GLfloat* boxArray, NSUInteger boxesDetected, CMTime frameTime);

// These images are only enabled when built with DEBUGLINEDETECTION defined, and are used to examine the intermediate states of the Hough transform
@property(nonatomic, readonly, strong) NSMutableArray *intermediateImages;

@end
