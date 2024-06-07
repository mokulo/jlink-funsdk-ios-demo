//
//  CaptureManager.m
//  VideoTest
//
//  Created by zhang on 2023/3/11.
//
///
///摄像头控制类，输出抓取的视频数据
///
///功能类流程：
///1、初始化摄像头，已摄像头对象初始化输入输出源，然后已输入输出源初始化视频会话对象
///2、视频会话对象开始运行（开始摄像）
///3、输出源回调方法被系统调用，开始回调视频数据（yuv420格式），然后回调给上层控制器
///
///
#define RATE 30 //摄像机默认帧率

#import "JFCaptureManager.h"

@interface JFCaptureManager () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *captureSession;
    AVCaptureConnection* connectionVideo;
    AVCaptureDevice *cameraDevice;
    AVCaptureDeviceInput *inputCameraDevice;
    
    uint8_t *y_frame;
    uint8_t *uv_frame;
    uint8_t *yuv_frame;
    
    int cameraRate;  //摄像机采集帧率
    int deviceRate;  //设备支持的帧率
    int devWidth;  //设备支持的视频分辨率宽度值
    int devHeight;  //设备支持的视频分辨率高度值
    int inputYuvNumber;  //yuv输入序号，部分YUV数据需要丢掉 （例如手机帧率30，设备需要帧率10，一秒就需要丢包20）
    int outputYuvNumber;  //yuv序号,当前有效输出的yuvnumber
    BOOL isBackGroundCamrea; //  是否是后置摄像头
}

@end

@implementation JFCaptureManager


-(id)init{
    self = [super init];
    [self initCamera];
    return self;
}
- (void)initPreviewLayer {
    if (!self.previewLayer) {
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        self.previewLayer.masksToBounds = YES;
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}
- (void)setDeviceFrameRate:(int)rate {
    deviceRate = rate;
    if (deviceRate > cameraRate) {
        cameraRate = rate;
        //视频会话准备完毕
        if([inputCameraDevice.device lockForConfiguration:nil]) {
            //最小帧间隔，反过来就是最大帧率， 20fps
            inputCameraDevice.device.activeVideoMinFrameDuration = CMTimeMake(1, rate);
            //最大帧间隔，反过来就是最小帧率，15fps
            inputCameraDevice.device.activeVideoMaxFrameDuration = CMTimeMake(1, rate);
            [inputCameraDevice.device unlockForConfiguration];
        }
    }
}
- (void)setDeviceFrameWidth:(float)width frameHeight:(float)height {
    devHeight = height;
    devWidth = width;
}
//初始化手机镜头
- (void) initCamera{
    //取出默认摄像头对象
    cameraDevice =  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //根据摄像头对象初始化视频输入源
    NSError *deviceError;
    inputCameraDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    //初始化视频数据输出源，设置输出属性
    AVCaptureVideoDataOutput *outputVideoDevice = [[AVCaptureVideoDataOutput alloc] init];
    //设置视频数据输出格式，这里是YUV420p格式
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:val forKey:key];
    outputVideoDevice.videoSettings = videoSettings;
    [outputVideoDevice setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    
    //获取当前相机的方向（前/后）
    AVCaptureDevicePosition position = [[inputCameraDevice device] position];
    //初始化视频会话
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:inputCameraDevice];
    [captureSession addOutput:outputVideoDevice];
    [captureSession beginConfiguration];
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset640x480]];
    connectionVideo = [outputVideoDevice connectionWithMediaType:AVMediaTypeVideo];
    //设置输出数据方向为竖屏（iphone手机拍照默认是横屏，系统相机和相册也是拍照之后把图像重新调整为竖屏）
    //[self setRelativeVideoOrientation];
    //视频会话准备完毕
    if([inputCameraDevice.device lockForConfiguration:nil]) {
        cameraRate = deviceRate = RATE;
        //最小帧间隔，反过来就是最大帧率， 20fps
        inputCameraDevice.device.activeVideoMinFrameDuration = CMTimeMake(1, cameraRate);
        //最大帧间隔，反过来就是最小帧率，15fps
        inputCameraDevice.device.activeVideoMaxFrameDuration = CMTimeMake(1, cameraRate);
        [inputCameraDevice.device unlockForConfiguration];
    }
    [captureSession commitConfiguration];
    
    [self initPreviewLayer];
}

-(AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

//- (void)setNeedChangePhoneShot:(BOOL)need{
//    needChangePhoneShot = need;
//}

-(void)changeAVCaptureDevicePosition:(BOOL)isBackGroundCamera{
    //获取摄像头的数量（该方法会返回当前能够输入视频的全部设备，包括前后摄像头和外接设备）
    NSInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    //摄像头的数量小于等于1的时候直接返回
    if (cameraCount <= 1) {
        return;
    }
    AVCaptureDevice *newCamera = nil;
    AVCaptureDeviceInput *newInput = nil;
    //获取当前相机的方向（前/后）
    AVCaptureDevicePosition position = [[inputCameraDevice device] position];
    
    //为摄像头的转换加转场动画
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.duration = 0.5;
    animation.type = @"oglFlip";
    
    if (isBackGroundCamera) {
//        isBackGroundCamera = YES;
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        animation.subtype = kCATransitionFromLeft;
            
        
    } else {
//        isBackGroundCamera = NO;

        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        animation.subtype = kCATransitionFromRight;
       
    }
    
//    if (position == AVCaptureDevicePositionFront) {
//        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
//        animation.subtype = kCATransitionFromLeft;
//        
//    }else if (position == AVCaptureDevicePositionBack){
//        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
//        animation.subtype = kCATransitionFromRight;
//    }
    //输入流
    newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
    if (newInput != nil) {
        [captureSession beginConfiguration];
        //先移除原来的input
        [captureSession removeInput:inputCameraDevice];
        if ([captureSession canAddInput:newInput]) {
            [captureSession addInput:newInput];
            inputCameraDevice = newInput;
        }else{
            //如果不能加现在的input，就加原来的input
            [captureSession addInput:inputCameraDevice];
        }
        if([inputCameraDevice.device lockForConfiguration:nil]) {
            //最小帧间隔，反过来就是最大帧率， 20fps
            inputCameraDevice.device.activeVideoMinFrameDuration = CMTimeMake(1, cameraRate);
            //最大帧间隔，反过来就是最小帧率，15fps
            inputCameraDevice.device.activeVideoMaxFrameDuration = CMTimeMake(1, cameraRate);
            [inputCameraDevice.device unlockForConfiguration];
        }
        [captureSession commitConfiguration];
    }
}

#pragma mark - 获取当前相机的方向（前(0)/后(1)）
-(int)getCurrentPosition
{
    AVCaptureDevicePosition position = [[inputCameraDevice device] position];
    if (position == AVCaptureDevicePositionFront) {
        return 0;
    }else{
        return 1;
    }
}

#pragma mark - 2、私有方法
#pragma mark 开始摄像
- (void)startCamera {
    inputYuvNumber = outputYuvNumber = 0;
    __block JFCaptureManager *blockSelf = (JFCaptureManager*)self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [blockSelf->captureSession startRunning];
//        [blockSelf changeAVCaptureDevicePosition:blockSelf->isBackGroundCamrea];
         
    });
}

#pragma mark 停止摄像
- (void)stopCamera {
    __block JFCaptureManager *blockSelf = (JFCaptureManager*)self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [blockSelf->captureSession stopRunning];
    });
}

#pragma mark 视频采集回调
-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
    
    //当前帧率需要丢包
    if ([self LossYUV]) {
        return;
    }
    
    //不裁剪
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    //时间戳
    CMTime decodeTime = CMSampleBufferGetDecodeTimeStamp(sampleBuffer);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    //图像宽度（像素）
    float pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    //图像高度（像素）
    float pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    int y_Size = pixelWidth * pixelHeight;
    
    yuv_frame = malloc(y_Size*3/2);

    //获取CVImageBufferRef中的y数据
    y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    //获取CMVImageBufferRef中的uv数据
    uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    memcpy(yuv_frame, y_frame, y_Size);
    memcpy(yuv_frame+y_Size, uv_frame, y_Size/2);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    unsigned char * yuv420pBuffer  = [self NV12ToyuvI420:pixelWidth h:pixelHeight buffer:(unsigned char*)yuv_frame];
    size_t yuv_size = y_Size *3/2;
    unsigned char * yuv420pRotate = malloc(yuv_size);
    YUV420Rotate90(yuv420pRotate, yuv420pBuffer, pixelWidth, pixelHeight);
    
    
    if (self.captureDelegate) {
        [self.captureDelegate videoCaptureCallback:yuv420pRotate width:pixelHeight height:pixelWidth];
    }
    
    free(yuv_frame);
    free(yuv420pBuffer);
    free(yuv420pRotate);
    
    //裁剪
//    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
//    //时间戳
//    CMTime decodeTime = CMSampleBufferGetDecodeTimeStamp(sampleBuffer);
//
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//    //图像宽度（像素）
//    float pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
//    //图像高度（像素）
//    float pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
//
//    //获取CVImageBufferRef中的y数据
//    y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//    //获取CMVImageBufferRef中的uv数据
//    uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//
//    [self videoCutFromWidth:pixelWidth height:pixelHeight];
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//
//    unsigned char * yuv420pBuffer  = [self NV12ToyuvI420:devWidth h:devHeight buffer:(unsigned char*)yuv_frame];
//    size_t yuv_size = devWidth * devHeight *3/2;
//    unsigned char * yuv420pRotate = malloc(yuv_size);
//    YUV420Rotate90(yuv420pRotate, yuv420pBuffer, devWidth, devHeight);
//
//
//    if (self.captureDelegate) {
//        [self.captureDelegate videoCaptureCallback:yuv420pRotate width:devHeight height:devWidth];
//    }
//
//    free(yuv_frame);
//    free(yuv420pBuffer);
//    free(yuv420pRotate);
}


- (void)videoCutFromWidth:(float)width height:(float)height {
    
    //裁剪中心区域画面
    yuv_frame = malloc(devHeight*devWidth*3/2);
    uint8_t * uv2 = malloc(devWidth*devHeight/2);
    int stepY ,stepY2 = 0;
    int stepuv, stepuv2 = 0;

    int startH = (height - devHeight)/2;
    int startW = (width - devWidth)/2;
    
    for (int i =startH; i< devHeight+startH; i++) {
        stepY = width*i+startW;
        stepY2 = devWidth*(i-startH);
        memcpy(yuv_frame+stepY2, y_frame+stepY, devWidth);
    }
    
    for (int i =startH; i< devHeight+startH; i++) {
        if (i%2 == 0){
            stepuv = (width*i)/2+startW;
            stepuv2 = devWidth*(i-startH)/2;
            memcpy(uv2+stepuv2, uv_frame+stepuv, devWidth);
        }
    }
    memcpy(yuv_frame+devHeight*devWidth, uv2, devHeight*devWidth/2);
    free(uv2);
    
}

- (unsigned char *)NV12ToyuvI420:(int)w h:(int)h buffer:(unsigned char *)NV12{
    unsigned char * I420 = (unsigned char *)malloc(w * h * 3 / 2);
    memcpy(I420,NV12,w*h);
    for(int i = 0,j = 0;i<w*h/4;i++,j+=2) {
        memcpy(I420+w*h+i,NV12+w*h+j,1);
        memcpy(I420+w*h+i+w*h/4,NV12+w*h+j+1,1);
    }
    return  I420;
}

- (void)setRelativeVideoOrientation {
    connectionVideo.videoOrientation = AVCaptureVideoOrientationPortrait;
}

void YUV420Rotate90(unsigned char *des,unsigned char *src,int width,int height)
{
    int n = 0;
    int hw = width / 2;
    int hh = height / 2;
    //copy y
    for(int j = 0; j < width;j++)
    {
        for(int i = height - 1; i >= 0; i--)
        {
            des[n++] = src[width * i + j];
        }
    }

    //copy u
    unsigned char *ptemp = src + width * height;
    for(int j = 0;j < hw;j++)
    {
        for(int i = hh - 1;i >= 0;i--)
        {
            des[n++] = ptemp[ hw*i + j ];
        }
    }

    //copy v
    ptemp += width * height / 4;
    for(int j = 0; j < hw; j++)
    {
        for(int i = hh - 1;i >= 0;i--)
        {
            des[n++] = ptemp[hw*i + j];
        }
    }
}

void YUV420Rotate270(unsigned char *des,unsigned char *src,int width,int height)
{
    int n = 0;
    int hw = width / 2;
    int hh = height / 2;
    //copy y
    for(int j = width - 1; j >= 0; j--)
    {
        for(int i = 0; i < height; i++)
        {
            if(j >= 0 && i < height && j < width && i >= 0)
            {
                des[n] = src[width * i + j];
            }
            n++;
        }
    }

    //copy u
    unsigned char *ptemp = src + width * height;
    for(int j = hw - 1; j >= 0; j--)
    {
        for(int i = 0; i < hh; i++)
        {
            if(j >= 0 && i < hh && j < hw && i >= 0)
            {
                des[n] = ptemp[hw * i + j];
            }
            n++;
        }
    }

    //copy v
    ptemp += width * height / 4;
    for(int j = hw - 1; j >= 0; j--)
    {
        for(int i = 0; i < hh; i++)
        {
            if(j >= 0 && i < hh && j < hw && i >= 0)
            {
                des[n] = ptemp[hw * i + j];
            }
            n++;
        }
    }
}

//根据设备帧率和录制帧率，确定当前帧是否丢包
- (BOOL)LossYUV {
    if (deviceRate < cameraRate) {
        if ((deviceRate * inputYuvNumber + cameraRate)/cameraRate > outputYuvNumber) {
            inputYuvNumber++;
            outputYuvNumber ++;
            return YES;
        }
    }
    inputYuvNumber++;
    //帧率一致，不做丢包
    return NO;
}

@end
