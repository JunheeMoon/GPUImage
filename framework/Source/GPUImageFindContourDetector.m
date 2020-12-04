#import "GPUImageFindContourDetector.h"

// Simple Demo : https://github.com/JunheeMoon/iOS-Image-Processing-using-GPUImage-Framework

// This applies a Suzuki85 Algorithm (OpenCV's findcontour) to detect text object in a scene.
// This approach is based entirely on the Suzuki Algorithm below
//Suzuki, S., and Be, K. (1985). Topological structural analysis of digitized binary images by border following. Computer Vision, Graphics, and Image Processing 30, 32–46. doi:10.1016/0734-189X(85)90016-7.

/*
 Suzuki85 Algorithm for GPUImage IOS Ojbective-C
  modified from "https://github.com/opencv/opencv/blob/master/modules/imgproc/src/contours.cpp"
 
 The 3-Clause BSD License
 SPDX short identifier: BSD-3-Clause

 Note: This license has also been called the "New BSD License" or "Modified BSD License". See also
  the 2-clause BSD License.

 Copyright @ 2020 Junhee Moon

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
 
@interface GPUImageFindContourDetector()

- (void)extractLineParametersFromImageAtFrameTime:(CMTime)frameTime;

@end

@implementation GPUImageFindContourDetector
#define  CV_INIT_3X3_DELTAS( deltas, step, nch )            \
    ((deltas)[0] =  (nch),  (deltas)[1] = -(step) + (nch),  \
     (deltas)[2] = -(step), (deltas)[3] = -(step) - (nch),  \
     (deltas)[4] = -(nch),  (deltas)[5] =  (step) - (nch),  \
     (deltas)[6] =  (step), (deltas)[7] =  (step) + (nch))
 
typedef struct CvPoint
{
    int x;
    int y;

#ifdef CV__VALIDATE_UNUNITIALIZED_VARS
    CvPoint() __attribute__(( warning("Non-initialized variable") )) {}
    template<typename _Tp> CvPoint(const std::initializer_list<_Tp> list)
    {
        CV_Assert(list.size() == 0 || list.size() == 2);
        x = y = 0;
        if (list.size() == 2)
        {
            x = list.begin()[0]; y = list.begin()[1];
        }
    };
#elif defined(CV__ENABLE_C_API_CTORS) && defined(__cplusplus)
    CvPoint(int _x = 0, int _y = 0): x(_x), y(_y) {}
    template<typename _Tp>
    CvPoint(const cv::Point_<_Tp>& pt): x((int)pt.x), y((int)pt.y) {}
#endif
#ifdef __cplusplus
    template<typename _Tp>
    operator cv::Point_<_Tp>() const { return cv::Point_<_Tp>(cv::saturate_cast<_Tp>(x), cv::saturate_cast<_Tp>(y)); }
#endif
}
CvPoint;

GLfloat *cornersArray;
GLfloat *boxArray;
static const CvPoint icvCodeDeltas[8] =
{ {1, 0}, {1, -1}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}, {0, 1}, {1, 1} };
 
typedef signed char schar;
@synthesize cornersDetectedBlock;
@synthesize boxesDetectedBlock;
  
- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    } 
    cv_filter=[[GPUImageColorInvertFilter alloc]init];
    
    [self addFilter:cv_filter];
    __unsafe_unretained GPUImageFindContourDetector *weakSelf = self;
    [cv_filter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime) {
        [weakSelf extractLineParametersFromImageAtFrameTime:frameTime];
    }];
     
    self.initialFilters = [NSArray arrayWithObjects:cv_filter, nil];
    // self. = [NSArray arrayWithObjects:initFilter, nil];
    self.terminalFilter = cv_filter;
    
    return self;
}

- (void)dealloc;
{
    free(rawImagePixels);
    free(cornersArray);
    free(boxArray);
}
NSUInteger numberOfCorners = 0;
NSUInteger numberOfBoxes = 0;
unsigned int cornerStorageIndex = 0;
unsigned int boxStorageIndex = 0;
CGSize imageSize ;
#pragma mark -
#pragma mark Corner extraction
//cvFindNextContour
- (void)extractLineParametersFromImageAtFrameTime:(CMTime)frameTime;
{
    bool debugyn=false;
    // we need a normal color texture for this filter
    NSAssert(self.outputTextureOptions.internalFormat == GL_RGBA, @"The output texture format for this filter must be GL_RGBA.");
    NSAssert(self.outputTextureOptions.type == GL_UNSIGNED_BYTE, @"The type of the output texture of this filter must be GL_UNSIGNED_BYTE.");
    boxStorageIndex =0;numberOfBoxes =0;
    numberOfCorners = 0;cornerStorageIndex = 0;
    imageSize = cv_filter.outputFrameSize;
    NSLog(@"filter1 width height : %f %f  ", imageSize.width ,imageSize.height);
    unsigned int imageByteSize = imageSize.width * imageSize.height * 4;
    
    if (rawImagePixels == NULL)
    {
        rawImagePixels = (GLbyte *)malloc(imageByteSize);
        cornersArray = calloc(1024 * 2 * 100, sizeof(GLfloat));
        boxArray = calloc(1024 * 2 * 100, sizeof(GLfloat));
    }
    rawImagePixels_temp=rawImagePixels;
    if(debugyn)NSLog(@"width height : %f %f  ", imageSize.width ,imageSize.height);
    glReadPixels(0, 0, (int)imageSize.width, (int)imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
    
    unsigned int imageWidth = imageSize.width * 4;
    unsigned int currentByte = 0; 
      
  //  CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    int t_i=0;
    bool PAGE_TEST =false;
    if(PAGE_TEST){
        currentByte=0;
        if(debugyn)NSLog(@"imageByteSize : %d    ", imageByteSize ); //640*480 * 4
        while (currentByte < imageByteSize)
        {
            GLbyte colorByte = rawImagePixels[currentByte];
            if ((colorByte)> 0)
            {
                unsigned int x = currentByte % imageWidth;
                unsigned int y = currentByte / imageWidth;
                NSLog(@"currentByte : %d   %x   (%d,%d)", currentByte ,colorByte, x/4 ,y);
            }else{
               t_i++;
            }
            currentByte +=4;
        }
    }
    int lnbd_x=0;
    int lnbd_y=1;
    
    currentByte=0;
    int height=(int)imageSize.height, width=(int)imageSize.width;
    //width=278;height=270;
    int x=1,y=1;
    int step=width*4;
    int prev =rawImagePixels[x-1];
    int p=0;
   //int new_mask = -2;
    int contourCnt=0;
    if(debugyn)NSLog(@"prev :  %x",prev );
    for(;y<height;y++,rawImagePixels+=step){
        
        for(;x<width;x++){
            if (prev > 0)
            {
                if(debugyn)NSLog(@"prev : %d ",(prev) );
            }
             
            for(;x<width&&(p=rawImagePixels[x*4])==prev;x++);
            
            if(x>=width)break;
            
            {
                int is_hole = 0;
                //if ( !(prev == 0 && p == 1)   )  //원래 p 값은 fffff인데 타입형때문에 -1로 인식됨. 
                if ( !(prev == 0 && p == -1)   )  //0이었다가 1이된 경우가 아닌경우  1->0 이 된경우,0->0,1->1
                {
                           //  cout << "내부일 경우 홀체크 && is hole 1로 세팅함" << endl;
                           /* check hole 홀체크 */
                           //if ( p != 0 || prev < 1 ) {  //1인데 0이었던경우
                           if ( p != 0 || prev == 0 ) {  //1인데 0이었던경우
                               //cout << "내부일 경우 홀체크 && is hole 1로 세팅함 >++>  리쥼되는 조건" << "x :" << x << "\t  y :" << y << endl;
                               //다음으로 넘김!!
                               goto resume_scan;
                           }
                           //if (prev & new_mask)
                           if (prev >0)
                           {
                               //  prev & new_mask
                               //not resume_scan, following line
                                if(debugyn)NSLog(@ "내부일 prev & new_mask : x :%d\t  y :%d",x,y);
                               //lnbd.x = x - 1; //이거가 시작점 세팅
                               lnbd_x = x - 1;
                           }
                           is_hole = 1;
                }
            
                if ( (is_hole || rawImagePixels_temp[(lnbd_y *  step) + lnbd_x] > 0)) {
                    //NSLog(@"모드0일때 -->  홀[%d]",is_hole);
                    // cout << "모드0일때 -->  홀["<< is_hole <<"]이거나 img0의 시작점이 0아니면!!(선일경우) ["<< bitset<4>(img0[lnbd.y * static_cast<size_t>(step) + lnbd.x] ) <<"] resume x:" << x << "   y:" << y <<" INBD x y :"<< lnbd.x  <<","<< lnbd.y<< endl;
                    goto resume_scan;
                }
                else {
                    //NSLog(@"모드0일때 -->  홀[%d]",is_hole);
                    //cout << "모드0일때 -x->  홀[" << is_hole << "]이거나 img0의 시작점이 0아니면!!(선일경우) [" << bitset<4>(img0[lnbd.y * static_cast<size_t>(step) + lnbd.x]) << "resume x:" << x << "   y:" << y << " INBD x y :" << lnbd.x << "," << lnbd.y << endl;
                }
                if(debugyn) NSLog(@"This is starting point. for fetch");
                [GPUImageFindContourDetector icvFetchContour: rawImagePixels+(x-is_hole)*4  stepV:step ptxV:x ptyV:y];
                contourCnt++;
                 
            }
        resume_scan: {
                prev=p;
                //if(prev&-2){
                if(prev>0){ //1110  0이나 1이 아닐때.  0000 이나 1111이 아닐때 .
                    if(debugyn)NSLog(@"Should not be here");
                    lnbd_x=x;
                }
            }
        }
        lnbd_x=0;
        lnbd_y=y+1;
        prev=0;
        x=1;
    }
    rawImagePixels=rawImagePixels_temp;

   // CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
    //NSLog(@"Processing time : %f ms     - t_i  : %d   numberOfBoxes : %d  contourCnt:%d", 1000.0 * currentFrameTime  , t_i,numberOfBoxes,contourCnt);
     
    /*
    if (cornersDetectedBlock != NULL)
    {
        cornersDetectedBlock(boxArray, numberOfBoxes, frameTime);
    }*/
    if (boxesDetectedBlock != NULL)
    {
        boxesDetectedBlock(boxArray, numberOfBoxes, frameTime);
    }
}
int MAX_SIZE=16;


+ (void) icvFetchContour : (GLbyte*) ptr stepV: (int) step ptxV: (int) ptx ptyV: (int) pty;
{
    
    GLfloat minX=99999,minY=99999,maxX=0,maxY=0;
    bool debugyn=false;
    //GLbyte nbd =2;
    int deltas[MAX_SIZE];
    GLbyte* i0 = ptr, * i1, * i3, * i4 = 0; //포인터
    int             prev_s = -1, s, s_end; //3x3에서 위치
    int             method = 0;//_method - 1;

    CV_INIT_3X3_DELTAS(deltas, step, 4); //step이랑 한줄단위를 기준으로 상하좌우 좌표를 들고옴 --> 상대좌표임!! 특정좌표에서 deltas를 더하면 해당위치로 이동됨! 일종의 나침반.
     
    memcpy(deltas + 8, deltas, 8 * sizeof(deltas[0]));

   // int CV_IS_SEQ_HOLE =-1;
    s_end = s = 4;//CV_IS_SEQ_HOLE ? 0 : 4;  //홀이면 0부터시작, 아니면 4부터시작
    
    //i1찾기
    do
    {

        //cout << " s : " << s <<  endl;  //
        s = (s - 1) & 7;
        //cout << " s : " << s << endl;  //
        i1 = i0 + deltas[s];
        //cout << " sizeof i1:" << sizeof(*i1) << " i0:" << *i0 << " deltas["<< s <<"]:"<< deltas[s] << " s : " << s <<" s_end:"<<s_end << endl;  //
         
       if(debugyn) NSLog(@"TEST %d %d" ,s, *i1);
    } while (*i1 == 0 && s != s_end);
    if (s == s_end)            /* single pixel domain */
    {
        *i0 = 2 ;//(schar)(nbd | -128);
        if (method >= 0)
        {
            //CV_WRITE_SEQ_ELEM(pt, writer);
        }
    }
    else
    {
        i3 = i0;
        prev_s = s ^ 4;

        /* follow border */
        for (;; )
        {
           // cout << " i0:" << &i0 << " i1:" << &i1 << " i3:" << &i3 << " i4:" << &i4 << endl;  //
           // cout << "f i0:" << &i0 << " i1:" << &i1 << " i3:" << &i3 << " i4:" << &i4 << endl;  //
            s_end = s;
            s = MIN(s,MAX_SIZE-1);//std::min(s, MAX_SIZE - 1); //MAX_SIZE  -1 (1111 4bit)

           // cout << " s_end:" << bitset<4>(s_end) << " s:" << bitset<4>(s) << "" << " MAX_SIZE " << bitset<8>(MAX_SIZE) << endl;

            /***
                1을 발견한다
            */
            //i4
            //s0~7 또는 i4는 0이아니게될떄!(뭔가 1이 발견된지점)
            while (s < MAX_SIZE - 1)
            {
               // cout << " i3:" << bitset<4>(*i3) << " deltas[s]:" << deltas[s]  << "s:"<< s;
                i4 = i3 + deltas[++s];
               // cout << " i4:" << bitset<4>(*i4)   << endl;

                //CV_Assert(i4 != NULL);
                if (*i4 != 0)
                    break;
            }

            //cout << " 7:" << bitset<4>(7) << " s:" << bitset<4>(s) << " s & 7 :" << bitset<4>(s&7)<< endl;

            //cout << " s:" << bitset<8>(s)  ;

            s &= 7;
            // cout << ">> &7 s:" << bitset<8>(s) << endl;

            //schar 1byte = 8bits   128~128

            /* check "right" bound */
            //cout << "(s - 1) :" << bitset<8>((s - 1)) << " s_end: " << bitset<8>(s_end)  << " >>> " ;
            if ((unsigned)(s - 1) < (unsigned)s_end)
            {
               // cout << "rrr (nbd | -128)" << (nbd | -128) <<""<< bitset<8>((nbd | -128)) << endl;
                *i3 = -2;//(schar)(nbd | -128);
                //cout << "rrr *i3:" << bitset<8>(*i3) << "nbd " << bitset<8>(nbd) << "sizeof nbd"<< sizeof (schar) <<endl;
            }
            else if (*i3 == -1)
            {
                *i3 = 2;//nbd;
                //cout << "111 *i3:" << bitset<8>(*i3) << "nbd " << bitset<8>(nbd) << endl;
            }

            if (method < 0)//여기 안들어옴!! method ==>0임
            {
                
               // schar _s = (schar)s;

                //CV_WRITE_SEQ_ELEM(_s, writer);
            }
            else
            {
               // cout << "@@ s " << bitset<8>(s) << "    prev_s " << bitset<8>(prev_s)  ;
                if (s != prev_s || method == 0)//방향이 바뀌었으면 저장! 아니면 저장하지않고 이동만함.
                {
                   // CV_WRITE_SEQ_ELEM(pt, writer); //선에대한 점을 하나씩 저장함???  //pt의 내용을 writer에 쓰고, writer에 있는 ptr을 elem만큼 ++ 이동
                    // cout << "저장::: pt.x " << pt.x << " pt.y " << pt.y << "" << endl; //선따라서 한바쿠돔
                    prev_s = s;
                    cornersArray[cornerStorageIndex++] = (CGFloat)(ptx)/ imageSize.width;
                    cornersArray[cornerStorageIndex++] = (CGFloat)(pty)/imageSize.height;
                    numberOfCorners++;
                    numberOfCorners = MIN(numberOfCorners, 512*100);
                    cornerStorageIndex = MIN(cornerStorageIndex, 1024*100);
                    //
                    
                    minX= MIN(minX, (CGFloat)(ptx)/ imageSize.width);
                    minY = MIN(minY,(CGFloat)(pty)/imageSize.height);
                    maxX= MAX(maxX,(CGFloat)(ptx)/ imageSize.width);
                    maxY = MAX(maxY,(CGFloat)(pty)/imageSize.height);
  

                    // NSLog(@"%d %d %d %d",ptx,pty, i3,i4);
                  //  if(debugyn)NSLog(@"%d %d %d %d",ptx,pty, i3,i4);
                }
                ptx+=icvCodeDeltas[s].x;
                pty+=icvCodeDeltas[s].y;
                //pt.x += icvCodeDeltas[s].x;
                //pt.y += icvCodeDeltas[s].y;
                //cout << " pt.x " << pt.x << " pt.y " << pt.y << "" << endl; //선따라서 한바쿠돔
                
            }
            //cout << " *i4:" << bitset<4>(*i4) << " *i3:" << bitset<4>(*i3) << "" << " i0:"<< bitset<4>(*i0) << "" << " i1:" << bitset<4>(*i1) << "" << endl;
            
            
            if (i4 == i0 && i3 == i1) //주소값이 처음 시작과 같은점인가?
                break;

           // NSLog(@"-=========" );
            i3 = i4;
            s = (s + 4) & 7; //반대로 이동!
        }
        /* end of border following loop */

    }
    boxArray[boxStorageIndex++]=minX;
    boxArray[boxStorageIndex++]=minY;
    boxArray[boxStorageIndex++]=maxX;
    boxArray[boxStorageIndex++]=maxY;
    //NSLog(@"boxArray [%d] %f %f %f %f",boxStorageIndex,minX,minY,maxX,maxY);
    numberOfBoxes ++;
    boxStorageIndex = MIN(boxStorageIndex, 1021*100);
}
- (BOOL)wantsMonochromeInput;
{
    return YES;
} 
#pragma mark -
#pragma mark Accessors
 

@end
