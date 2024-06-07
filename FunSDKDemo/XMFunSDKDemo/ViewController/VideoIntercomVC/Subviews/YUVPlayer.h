//
//  YUVPlayer.h
//  VideoTest
//
//  Created by zhang on 2023/3/11.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YUVPlayer : UIImageView


@property (nonatomic) CVPixelBufferRef pixelBuffer;

- (id)initWithFrame:(CGRect)frame;

- (void)clearImage;
@end

NS_ASSUME_NONNULL_END
