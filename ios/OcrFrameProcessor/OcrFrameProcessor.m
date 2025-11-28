#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>
#import <VisionCamera/Frame.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>

@interface OcrFrameProcessorPlugin : FrameProcessorPlugin
@end

@implementation OcrFrameProcessorPlugin

- (instancetype _Nonnull)initWithProxy:(VisionCameraProxyHolder*)proxy
                           withOptions:(NSDictionary* _Nullable)options {
  self = [super initWithProxy:proxy withOptions:options];
  
  // Log the options for debugging
  if (options != nil) {
    NSLog(@"OCR Plugin options: %@", options);
    NSString *model = options[@"model"];
    if (model != nil) {
      NSLog(@"Using model: %@", model);
      // TODO: Implement different model options based on 'model' parameter
      // Currently Vision Framework uses default settings
      // Future versions might support different accuracy/speed trade-offs
    }
  }
  
  return self;
}

- (id _Nullable)callback:(Frame* _Nonnull)frame
           withArguments:(NSDictionary* _Nullable)arguments {
  BOOL includeBoxes = [arguments objectForKey:@"includeBoxes"] ? [[arguments objectForKey:@"includeBoxes"] boolValue] : NO;
  BOOL includeConfidence = [arguments objectForKey:@"includeConfidence"] ? [[arguments objectForKey:@"includeConfidence"] boolValue] : NO;
  NSLog(@"Args includeBoxes=%@ includeConfidence=%@", includeBoxes ? @"YES" : @"NO", includeConfidence ? @"YES" : @"NO");
  
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(frame.buffer);
  if (pixelBuffer == NULL) {
    NSLog(@"Failed to get pixel buffer from frame");
    return nil;
  }
  
  CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
  if (ciImage == nil) {
    NSLog(@"Failed to create CIImage from pixel buffer");
    return nil;
  }

  CGImagePropertyOrientation orientation = [self cgImageOrientationFromUIImageOrientation:frame.orientation];
  VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:ciImage orientation:orientation options:@{}];
  if (handler == nil) {
    NSLog(@"Failed to create VNImageRequestHandler");
    return nil;
  }

  __block NSMutableArray<NSDictionary *> *lineResults = [NSMutableArray array];

  VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
    if (error != nil) {
      NSLog(@"OCR recognition failed: %@", error);
      // Note: Semaphore is signaled outside this handler, so early return is safe
      return;
    }

    for (VNRecognizedTextObservation *observation in request.results) {
      VNRecognizedText *topCandidate = [[observation topCandidates:1] firstObject];
      if (topCandidate != nil) {
        NSMutableDictionary *line = [NSMutableDictionary dictionary];
        line[@"text"] = topCandidate.string;
        if (includeConfidence) {
          line[@"confidence"] = @(topCandidate.confidence);
        }
        if (includeBoxes) {
          CGRect rect = observation.boundingBox; // normalized [0,1] in Vision coordinates
          // Map to x,y,width,height in the same normalized space
          NSMutableDictionary *box = [NSMutableDictionary dictionary];
          box[@"x"] = @(rect.origin.x);
          box[@"y"] = @(rect.origin.y);
          box[@"width"] = @(rect.size.width);
          box[@"height"] = @(rect.size.height);
          line[@"box"] = box;
        }
        [lineResults addObject:line];
      }
    }
  }];
  
  if (request == nil) {
    NSLog(@"Failed to create VNRecognizeTextRequest");
    return nil;
  }

  // Configure iOS-specific options
  NSString *level = [arguments objectForKey:@"recognitionLevel"];
  if ([level isKindOfClass:[NSString class]]) {
    if ([level isEqualToString:@"accurate"]) {
      request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    } else if ([level isEqualToString:@"fast"]) {
      request.recognitionLevel = VNRequestTextRecognitionLevelFast;
    }
  }
  NSArray<NSString *> *languages = [arguments objectForKey:@"recognitionLanguages"];
  if ([languages isKindOfClass:[NSArray class]]) {
    request.recognitionLanguages = languages;
  }
  NSNumber *useCorrection = [arguments objectForKey:@"usesLanguageCorrection"];
  if ([useCorrection isKindOfClass:[NSNumber class]]) {
    request.usesLanguageCorrection = [useCorrection boolValue];
  }

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSError *error = nil;
    [handler performRequests:@[request] error:&error];
    if (error) {
      NSLog(@"Failed to perform OCR recognition: %@", error);
    }
    dispatch_semaphore_signal(semaphore);
  });

  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  if (lineResults.count == 0) {
    return nil;
  }
  NSMutableString *joinedText = [NSMutableString string];
  for (NSDictionary *line in lineResults) {
    NSString *t = line[@"text"];
    if (t != nil) {
      if (joinedText.length > 0) [joinedText appendString:@" "];
      [joinedText appendString:t];
    }
  }

  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  result[@"text"] = joinedText;
  if (includeBoxes) {
    // Represent lines under a blocks array with a single synthetic block for parity
    NSMutableDictionary *block = [NSMutableDictionary dictionary];
    block[@"text"] = joinedText;
    block[@"lines"] = lineResults;
    result[@"blocks"] = @[block];
  }
  return result;
}

- (CGImagePropertyOrientation)cgImageOrientationFromUIImageOrientation:(UIImageOrientation)orientation {
  switch (orientation) {
    case UIImageOrientationUp: return kCGImagePropertyOrientationUp;
    case UIImageOrientationDown: return kCGImagePropertyOrientationDown;
    case UIImageOrientationLeft: return kCGImagePropertyOrientationLeft;
    case UIImageOrientationRight: return kCGImagePropertyOrientationRight;
    case UIImageOrientationUpMirrored: return kCGImagePropertyOrientationUpMirrored;
    case UIImageOrientationDownMirrored: return kCGImagePropertyOrientationDownMirrored;
    case UIImageOrientationLeftMirrored: return kCGImagePropertyOrientationLeftMirrored;
    case UIImageOrientationRightMirrored: return kCGImagePropertyOrientationRightMirrored;
    default: return kCGImagePropertyOrientationUp;
  }
}

VISION_EXPORT_FRAME_PROCESSOR(OcrFrameProcessorPlugin, detectText)

@end
