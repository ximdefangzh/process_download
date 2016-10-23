//
//  ViewController.m
//  progress_show_Image
//
//  Created by ximdefangzh on 16/8/31.
//  Copyright © 2016年 ximdefangzh. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>

@interface ViewController ()<NSURLConnectionDataDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) NSInteger expectedSize;
@property (nonatomic, strong) NSMutableData *imageData;


@end

@implementation ViewController{
    size_t width, height;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageData = [NSMutableData data];
    
    NSURL *url = [NSURL  URLWithString:@"http://pic1.win4000.com/wallpaper/3/55cc1382140bc.jpg"];
//    NSData *data = [NSData dataWithContentsOfURL:url];
//    UIImage *img = [UIImage imageWithData:data];
//    self.imageView.image = img;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURLConnection *connect = [NSURLConnection connectionWithRequest:request delegate:self];
        [[NSRunLoop currentRunLoop] run];
    });

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.expectedSize = response.expectedContentLength;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{

    [self didReceiveData:data complete:^(UIImage *image) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.imageView.image = image;
        }];
    }];
//    [NSThread sleepForTimeInterval:1];
}


//抽取的核心代码
- (void)didReceiveData:(NSData *)data complete:(void(^)(UIImage *image))completedBlock{
    [self.imageData appendData:data];
    
    if (self.expectedSize > 0) {
        const NSInteger totalSize = self.imageData.length;
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.imageData, NULL);
        
        if (width + height == 0) {
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            if (properties) {
                NSInteger orientationValue = -1;
                CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &height);
                val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &width);
                val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
                CFRelease(properties);
            }
            
        }
        
        if (width + height > 0 && totalSize <= self.expectedSize) {
            // Create the image
            CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
            
#ifdef TARGET_OS_IPHONE
            if (partialImageRef) {
                const size_t partialHeight = CGImageGetHeight(partialImageRef);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                if (bmContext) {
                    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
                    CGImageRelease(partialImageRef);
                    partialImageRef = CGBitmapContextCreateImage(bmContext);
                    CGContextRelease(bmContext);
                }
                else {
                    CGImageRelease(partialImageRef);
                    partialImageRef = nil;
                }
            }
#endif
            
            if (partialImageRef) {
                UIImage *image = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:UIImageOrientationUp];
                CGImageRelease(partialImageRef);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (completedBlock) {
                        completedBlock(image);
                    }
                }];
            }
        }
        
        CFRelease(imageSource);
    }
}

@end
