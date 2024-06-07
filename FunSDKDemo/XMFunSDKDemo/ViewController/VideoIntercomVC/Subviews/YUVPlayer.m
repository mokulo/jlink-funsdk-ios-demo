//
//  YUVPlayer.m
//  VideoTest
//
//  Created by zhang on 2023/3/11.
//

#import "YUVPlayer.h"

@interface YUVPlayer ()
{
    int pixelWidth;
    int pixelHeight;
    
    uint8_t *y_frame;
    uint8_t *uv_frame;
    uint8_t *yuv_frame;
}

@end

@implementation YUVPlayer


- (void)handlePanAction:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender translationInView:[sender.view superview]];
    
    CGFloat senderHalfViewWidth = sender.view.frame.size.width / 2;
    CGFloat senderHalfViewHeight = sender.view.frame.size.height / 2;
    
    __block CGPoint viewCenter = CGPointMake(sender.view.center.x + point.x, sender.view.center.y + point.y);
    // 拖拽状态结束
    if (sender.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.4 animations:^{
            if ((sender.view.center.x + point.x - senderHalfViewWidth) <= 12) {
                viewCenter.x = senderHalfViewWidth + 12;
            }
            if ((sender.view.center.x + point.x + senderHalfViewWidth) >= (SCREEN_WIDTH - 12)) {
                viewCenter.x = SCREEN_WIDTH - senderHalfViewWidth - 12;
            }
            if ((sender.view.center.y + point.y - senderHalfViewHeight) <= 12) {
                viewCenter.y = senderHalfViewHeight + 12;
            }
            if ((sender.view.center.y + point.y + senderHalfViewHeight) >= (SCREEN_HEIGHT - 12)) {
                viewCenter.y = SCREEN_HEIGHT - senderHalfViewHeight - 12;
            }
            sender.view.center = viewCenter;
        } completion:^(BOOL finished) {
            if(viewCenter.x >= SCREEN_WIDTH /2){
                [UIView animateWithDuration:0.3 animations:^{
                    viewCenter.x = SCREEN_WIDTH - senderHalfViewWidth - 10;
                    sender.view.center  = viewCenter;
                }];
            }else{
                [UIView animateWithDuration:0.3 animations:^{
                    viewCenter.x = senderHalfViewWidth + 10;
                    sender.view.center  = viewCenter;
                }];
            }
            
        }];
        [sender setTranslation:CGPointMake(0, 0) inView:[sender.view superview]];
    } else {
        // UIGestureRecognizerStateBegan || UIGestureRecognizerStateChanged
        viewCenter.x = sender.view.center.x + point.x;
        viewCenter.y = sender.view.center.y + point.y;
        sender.view.center = viewCenter;
        [sender setTranslation:CGPointMake(0, 0) inView:[sender.view superview]];
    }
}
    
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.contentMode = UIViewContentModeScaleAspectFit;
    self.backgroundColor = [UIColor blackColor];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanAction:)];
    [self addGestureRecognizer:panGestureRecognizer];
    self.userInteractionEnabled = YES;
    return self;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self prepareYUVBuffer:pixelBuffer];
    
    UIImage *image;
    //通过YUV生成image
    //image = [YUVPlayer imageForYUV:yuv_frame width:pixelWidth height:pixelHeight];

    //YUV转换为RGB，然后通过RGB生成image
    image = [self RGBFromYUV];
    
    //图片调整UV色（特殊处理YUV中的UV，就是色度）
    //image = [self colorChange];
    
    //图片调整Y色（特殊处理YUV中的Y，就是亮度）
    //image = [self colorChangeY];
    
    //图片半去色
    //image = [self colorChangeHalf];
    
    //YUV剪切，剪切前半部分YUV数据然后生成图像
    //image = [self yuvCut1];
    
    //YUV剪切，剪切头部一小块正方形，生成图像
    //image = [self yuvCut2];
    
    //YUV剪切模糊，剪切头部文件并模糊处理
    //image = [self headerCutDim];
    
    //YUV剪切模糊，剪切底部文件并模糊处理
    //image = [self footerCutDim];
    
    //YUV剪切模糊拼接，剪切文件并模糊处理，然后拼接到原画面上
    //image = [self cutAndJoint];
    
    if (image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.alpha = 1.0;
            self.image = image;
        });
    }
    CFRelease(pixelBuffer);
}

- (void)clearImage{
    self.image = nil;
}

- (UIImage*)yuvCut1 {
    //裁剪头部文件
    int cutHeight = 128;
    uint8_t * uv2 = malloc(cutHeight*cutHeight/2);
    uint8_t * yuv2 = malloc(cutHeight*cutHeight*3/2);
    
    memcpy(yuv2, y_frame, cutHeight*cutHeight);
    memcpy(yuv2+cutHeight*cutHeight, uv_frame, cutHeight*cutHeight/2);
    
    UIImage *image = [YUVPlayer imageForYUV:yuv2 width:pixelWidth height:cutHeight*cutHeight/pixelWidth];
    
    free(uv2);
    free(yuv2);
    
    return  image;
}

- (UIImage*)headerCutDim{
    //裁剪头部文件，并且模糊处理
    int cutHeight = 192;
    
    //临时YUV分量空间
    uint8_t * yuv2 = malloc(pixelWidth*cutHeight*3/2);
    memcpy(yuv2, yuv_frame, pixelWidth*cutHeight);
    memcpy(yuv2+pixelWidth*cutHeight, uv_frame, pixelWidth*cutHeight/2);
    
    //模糊之后的头部文件YUV分量
    uint8_t * yuvHeader = [self obfuscationyuv:yuv2 width:pixelWidth height:cutHeight];
    
    UIImage *image = [YUVPlayer imageForYUV:yuvHeader width:pixelWidth height:cutHeight];
    free(yuv2);
    free(yuvHeader);
    return  image;
}

- (UIImage*)footerCutDim{
    //裁剪头部文件，并且模糊处理
    int cutHeight = 192;
    
    int startIndexY = pixelWidth * (pixelHeight-192);
    int startIndexUV = pixelWidth *(pixelHeight-192) /2 ;
    //临时YUV分量空间
    uint8_t * yuv2 = malloc(pixelWidth*cutHeight*3/2);
    memcpy(yuv2, yuv_frame+startIndexY, pixelWidth*cutHeight);
    memcpy(yuv2+pixelWidth*cutHeight, uv_frame+startIndexUV, pixelWidth*cutHeight/2);
    
    //模糊之后的头部文件YUV分量
    uint8_t * yuvFooter = [self obfuscationyuv:yuv2 width:pixelWidth height:cutHeight];
    
    UIImage *image = [YUVPlayer imageForYUV:yuvFooter width:pixelWidth height:cutHeight];
    free(yuv2);
    free(yuvFooter);
    return  image;
}

- (UIImage*)cutAndJoint {
    //裁剪头部文件高度
    int cutHeight = 192;
   
    //临时YUV分量空间
    uint8_t * yuv2 = malloc(pixelWidth*cutHeight*3/2);
    memcpy(yuv2, yuv_frame, pixelWidth*cutHeight);
    memcpy(yuv2+pixelWidth*cutHeight, uv_frame, pixelWidth*cutHeight/2);
    
    //模糊之后的头部文件YUV分量
    uint8_t * yuvHeader = [self obfuscationyuv:yuv2 width:pixelWidth height:cutHeight];
    
    
    int height = cutHeight + pixelHeight;
    uint8_t * yuv3 = malloc(pixelWidth*height*3/2);
    
    //拷贝拼接部分的Y
    memcpy(yuv3, yuvHeader, pixelWidth*cutHeight);
    //拷贝原图像Y
    memcpy(yuv3+pixelWidth*cutHeight, yuv_frame, pixelWidth*pixelHeight);
    //拷贝拼接footer部分Y
    
    
    //拷贝拼接部分UV
    memcpy(yuv3+pixelWidth*cutHeight+pixelWidth*pixelHeight, yuvHeader+pixelWidth*cutHeight, pixelWidth*cutHeight/2);
    //拷贝原图像UV
    memcpy(yuv3+pixelWidth*cutHeight+pixelWidth*pixelHeight+pixelWidth*cutHeight/2, uv_frame, pixelWidth*pixelHeight/2);
    //拷贝拼接footer部分UV
    
    UIImage *image = [YUVPlayer imageForYUV:yuv3 width:pixelWidth height:height];
    
    free(yuv2);
    free(yuvHeader);
    free(yuv3);
    return  image;
}

- (UIImage*)RGBFromYUV {
    //YUV转RGB
    size_t rgbaSize = pixelWidth*pixelHeight*4;
    uint8_t *rgba = malloc(rgbaSize);

    int Y,U,V = 0;
    int R,G,B = 0;
    int stepY, stepUV = 0;
    
    //YUV转RGB显示图片

    for (int i=0; i< pixelHeight; i++) {
        for (int j =0; j< pixelWidth; j++) {
            stepY = i*pixelWidth+j;
            stepUV = i/2*pixelWidth + j/2*2;
            Y = y_frame[stepY];
            U = uv_frame[stepUV];
            V = uv_frame[stepUV+1];

            R = Y + ((360 * (V - 128))>>8) ; //R
            G = Y - (( ( 88 * (U - 128)  + 184 * (V - 128)) )>>8); //G
            B = Y +((455 * (U - 128))>>8);//B
            if (R < 0) R = 0;
            if (G < 0) G = 0;
            if (B < 0) B = 0;
            if (R > 255) R = 255;
            if (G > 255) G = 255;
            if (B > 255) B = 255;

            rgba[stepY*4+0] = (uint8_t)R;
            rgba[stepY*4+1] = (uint8_t)G;
            rgba[stepY*4+2] = (uint8_t)B;
            rgba[stepY*4+3] = (uint8_t)255;
        }
    }
    UIImage *image = [YUVPlayer imageForRGBA:rgba width:pixelWidth height:pixelHeight];
    free(rgba);
    return  image;
}

- (UIImage*)yuvCut2 {
    //裁剪正方形画面
    int cutHeight = 320; //iOS13以上步长改为64，因此裁剪宽和高必须是64的倍数
    uint8_t * yuv2 = malloc(cutHeight*cutHeight*3/2);
    uint8_t * uv2 = malloc(cutHeight*cutHeight/2);
    int stepY;
    int stepY2;
    int stepuv, stepuv2 = 0;

    for (int i =0; i< cutHeight; i++) {
        stepY = pixelWidth*i;
        stepY2 = cutHeight*i;
        memcpy(yuv2+stepY2, y_frame+stepY, cutHeight);
    }
    
    for (int i =0; i< cutHeight; i++) {
        if (i%2 == 0){
            stepuv = pixelWidth*i/2;
            stepuv2 = cutHeight*i/2;
            memcpy(uv2+stepuv2, uv_frame+stepuv, cutHeight);
        }
    }
    
    memcpy(yuv2+cutHeight*cutHeight, uv2, cutHeight*cutHeight/2);
    
    UIImage *image = [YUVPlayer imageForYUV:yuv2 width:cutHeight height:cutHeight];
    
    free(yuv2);
    
    return image;
}

- (UIImage*)colorChange {
    //图片去色
    uint8_t * uv2 = malloc(pixelWidth*pixelHeight/2);
    uint8_t * yuv2 = malloc(pixelWidth*pixelHeight*3/2);
    
    memcpy(yuv2, yuv_frame, pixelWidth*pixelHeight);
    memcpy(uv2, uv_frame, pixelWidth*pixelHeight/2);
    
    for (int i=0; i< pixelWidth*pixelHeight/2; i++) {
        uv2[i] = (uint8_t)128;
    }
    
    memcpy(yuv2+pixelWidth*pixelHeight, uv2, pixelWidth*pixelHeight/2);
    
    UIImage *image = [YUVPlayer imageForYUV:yuv2 width:pixelWidth height:pixelHeight];
    
    free(uv2);
    free(yuv2);
    
    return  image;
}
- (UIImage*)colorChangeY {
    //图片去亮Y
    uint8_t * yuv2 = malloc(pixelWidth*pixelHeight*3/2);
    
    memcpy(yuv2, yuv_frame, pixelWidth*pixelHeight*3/2);
    
    for (int i=0; i< pixelWidth*pixelHeight; i++) {
        yuv2[i] = (uint8_t)0;
    }
    
    UIImage *image = [YUVPlayer imageForYUV:yuv2 width:pixelWidth height:pixelHeight];
    
    free(yuv2);
    
    return  image;
}


- (UIImage*)colorChangeHalf {
    //图片半去色 本方法说明YUV格式为 YYYY YYYY UV UV
    uint8_t * uv2 = malloc(pixelWidth*pixelHeight/2);
    uint8_t * yuv2 = malloc(pixelWidth*pixelHeight*3/2);
    
    memcpy(yuv2, yuv_frame, pixelWidth*pixelHeight);
    memcpy(uv2, uv_frame, pixelWidth*pixelHeight/2);
    
    for (int i=0; i< pixelWidth*pixelHeight/8; i++) {
        uv2[i] = (uint8_t)128;
    }
    
    memcpy(yuv2+pixelWidth*pixelHeight, uv2, pixelWidth*pixelHeight/2);
    
    UIImage *image = [YUVPlayer imageForYUV:yuv2 width:pixelWidth height:pixelHeight];
    
    free(uv2);
    free(yuv2);
    
    return  image;
}


+(UIImage*)imageForYUV:(unsigned char *)buffer
                 width:(int)width
                height:(int)height {
    NSDictionary *pixelAttributes = @{(NSString*)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    
    CVPixelBufferRef pixelBuffer = NULL;
    
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    unsigned char *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    unsigned char *y_ch0 = buffer;
    unsigned char *y_ch1 = buffer + width * height;
    memcpy(yDestPlane, y_ch0, width * height);
    unsigned char *uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(uvDestPlane, y_ch1, width * height/2);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
    }
    CIImage *coreImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext *MytemporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef MyvideoImage = [MytemporaryContext createCGImage:coreImage fromRect:CGRectMake(0, 0, width, height)];
    
    UIImage *Mynnnimage = [UIImage imageWithCGImage:MyvideoImage];
    CVPixelBufferRelease(pixelBuffer);
    CGImageRelease(MyvideoImage);
    
    return Mynnnimage;
}

+ (UIImage *)imageForRGBA:(unsigned char *)rgba
                    width:(CGFloat)width
                   height:(CGFloat)height {
    
    int bytes_per_pix = 4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef newContext = CGBitmapContextCreate(rgba,
                                                    width, height, 8,
                                                    width * bytes_per_pix,
                                                    colorSpace, kCGImageAlphaPremultipliedLast);

    CGImageRef frame = CGBitmapContextCreateImage(newContext);
    
    UIImage *image = [UIImage imageWithCGImage:frame];
    
    CGImageRelease(frame);

    CGContextRelease(newContext);

    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (void)prepareYUVBuffer:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    //图像宽度（像素）
    pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    //图像高度（像素）
    pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    //yuv中的y所占字节数
    size_t y_size = pixelWidth * pixelHeight;
    //yuv中的uv所占的字节数
    size_t uv_size = y_size / 2;
    yuv_frame = malloc(uv_size + y_size);
    
    //获取CVImageBufferRef中的y数据
    y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yuv_frame, y_frame, y_size);
    
    //获取CMVImageBufferRef中的uv数据
    uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(yuv_frame + y_size, uv_frame, uv_size);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

-(uint8_t *) obfuscationyuv:(uint8_t *)yuvFrame width:(int)width height:(int)height {
    //读取原始数据YUV分量
    uint8_t * yuv = malloc(width*height*3/2);
    uint8_t * uv = malloc(width*height/2);
    memcpy(yuv, yuvFrame, width*height);
    memcpy(uv, yuvFrame+width*height, width*height/2);
    
    //YUV中转数据存储对象
    uint8_t * yuv2 = malloc(width*height*3/2);
    uint8_t * uv2 = malloc(width*height/2);

    //当前模糊操作的Y和UV单元位置
    int stepY, stepUV = 0;
    
    //模糊半径
    int radius = 3;
    int number = (radius*2+1)*(radius*2+1);
    
    //Y分量模糊
    for (int i=0; i< height; i++) {
        for (int j =0; j< width; j++) {
            
            stepY = i*width+j;
            int maxY = yuvFrame[stepY];
            
//            int yipermit;
//            int yjPermit;
//            if (i-radius< 0) {
//                yipermit = 0;
//            }
//            if (i+radius >= height) {
//                yipermit = height-1;
//            }
//            if (j-radius < 0) {
//                yjPermit = 0;
//            }
//            if (j+radius>= width) {
//                yjPermit = width-1;
//            }
            
            //以radius值为半径的圆形（这里为了好计算，用了2倍半径边长的正方形）
            for (int yi = i-radius; yi<= i+radius; yi++) {
                for (int yj = j-radius; yj<= j +radius; yj++) {
                    int yipermit = yi;
                    int yjPermit = yj;
                    if (yi<0) {
                        yipermit = 0;
                    }if (yi>= height) {
                        yipermit = height-1;
                    }if (yj < 0){
                        yjPermit = 0;
                    }if (yj >= width){
                        yjPermit = width-1;
                    }
                    int stepY2 = yipermit*width+yjPermit;
                    maxY +=  yuvFrame[stepY2];
                }
            }
            yuv2[stepY] = maxY/number;
        }
    }
    //UV分量模糊
    for (int i=0; i< height/2; i++) {
        for (int j =0; j< width/2; j++) {
            
            stepUV = i*width + j*2;
            int maxU = uv[stepUV];
            int maxV = uv[stepUV+1];
            
            for (int yi = i-radius; yi<= i+radius; yi++) {
                for (int yj = j-radius; yj<= j +radius; yj++) {
                    int yipermit = yi;
                    int yjPermit = yj;
                    if (yi<0) {
                        yipermit = 0;
                    }if (yi>= height/2){
                        yipermit = height/2-1;
                    }if (yj<0) {
                        yjPermit = 0;
                    }if (yj >= width/2){
                        yjPermit = width/2-1;
                    }
                    int stepUV2 = yipermit*width + yjPermit*2;
                    maxU +=  uv[stepUV2];
                    maxV += uv[stepUV2+1];
                }
            }
            uv2[stepUV] = maxU/number;
            uv2[stepUV+1] = maxV/number;
        }
    }
    
    //YUV数据合并
    memcpy(yuv, yuv2, width*height);
    memcpy(yuv+width*height, uv2, width*height/2);
    
    free(uv);
    free(uv2);
    free(yuv2);
    
    return  yuv;
}
@end
