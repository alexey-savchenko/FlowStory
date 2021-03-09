//
//  VideoUtility.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 14.01.2021.
//

import AVFoundation
import UIKit
import CoreImage
import UNILib
import Combine

func uniqueURL() -> URL {
  let id = UUID()
  
  let url = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent(id.uuidString)
    .appendingPathExtension("MP4")
  return url
}

func makeFlowVideo1(
  assetURL: URL
) -> AnyPublisher<AVAsset, Never> {
  let image = UIImage(contentsOfFile: assetURL.path)!
  let url = uniqueURL()
  let renderSize = CGSize(width: 1080, height: 1920)
  return Future { promise in
    createVideoFromImageSync1(
      image,
      size: renderSize,
      duration: 10,
      outputURL: url
    ) { (img, progress) -> CIImage in
      
      let params = scaleAndPositionInAspectFillMode(img.extent.size, in: renderSize)
      let filled = img >>> params
      
      let maxOffset = filled.extent.width - renderSize.width
      let offset = CGFloat(progress) * maxOffset
      
      let translated = filled
        .transformed(by: .init(translationX: -params.position.x, y: 0))
        .transformed(by: .init(translationX: -offset, y: 0))
        .cropped(to: .init(origin: .zero, size: renderSize))
      
      return translated
    } progress: { (progress) in
      print(progress)
    } result: { (asset) in
      promise(.success(asset))
    }

  }
  .eraseToAnyPublisher()
}

private let frameDuration = CMTime(value: 1, timescale: 30)

private func createVideoFromImageSync1(
  _ image: UIImage,
  size: CGSize,
  duration: TimeInterval,
  outputURL: URL,
  process: @escaping (CIImage, Double) -> CIImage,
  progress: ((Double) -> Void)?,
  result: @escaping (AVAsset) -> Void
) {
  
  let videoWriter = try! AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
  
  /// create the basic video settings
  let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: size.width,
    AVVideoHeightKey: size.height,
  ]
  
  /// create a video writter input
  let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
  
  /// create setting for the pixel buffer
  let sourceBufferAttributes: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
    kCVPixelBufferWidthKey as String: Float(size.width),
    kCVPixelBufferHeightKey as String: Float(size.height),
    kCVPixelBufferCGImageCompatibilityKey as String: NSNumber(value: true),
    kCVPixelBufferCGBitmapContextCompatibilityKey as String: NSNumber(value: true)
  ]
  
  /// create pixel buffer for the input writter and the pixel buffer settings
  let pixelBufferAdaptor =
    AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: videoWriterInput,
      sourcePixelBufferAttributes: sourceBufferAttributes
    )
  
  /// check if an input can be added to the asset
  assert(videoWriter.canAdd(videoWriterInput))
  
  /// add the input writter to the video asset
  videoWriter.add(videoWriterInput)
  
  while !videoWriter.startWriting() {
    print("Wait for start of writer for \(outputURL.lastPathComponent)")
    Thread.sleep(forTimeInterval: 1)
  }
  
  assert(pixelBufferAdaptor.pixelBufferPool != nil)
  
  let sourceCIImage = CIImage(image: image)!
  let ctx = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
  
  let media_queue = DispatchQueue(label: "mediaInputQueue", autoreleaseFrequency: .workItem)
  videoWriter.startSession(atSourceTime: CMTime.zero)
  videoWriterInput.requestMediaDataWhenReady(on: media_queue) {
    let frameCount = duration / frameDuration.seconds
    print("Number of frames - \(frameCount)")
    
    var nextStartTimeForFrame = CMTime.zero
    
    while nextStartTimeForFrame.seconds < duration {
      while !videoWriterInput.isReadyForMoreMediaData {
        print("Wait append for \(outputURL.lastPathComponent)")
        Thread.sleep(forTimeInterval: 0.1)
      }
      
      let percentComplete = nextStartTimeForFrame.seconds / duration
      
      let filteredImage = process(sourceCIImage, percentComplete)
      
      if !appendPixelBufferForImage(
        filteredImage,
        context: ctx,
        pixelBufferAdaptor: pixelBufferAdaptor,
        presentationTime: nextStartTimeForFrame
      ) {
        fatalError()
      }

      print("Appended frame at \(nextStartTimeForFrame.seconds) for \(outputURL.lastPathComponent)")
      
      progress?(percentComplete)
      nextStartTimeForFrame = nextStartTimeForFrame + frameDuration
    }
    
    videoWriterInput.markAsFinished()
    
    videoWriter.finishWriting {
      let asset = AVAsset(url: outputURL)
      print("Asset duration - \(asset.duration.seconds)")
      result(asset)
    }
  }
}

func buffer(from image: UIImage) -> CVPixelBuffer? {
  let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
  guard status == kCVReturnSuccess else {
    return nil
  }
  
  CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
  let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
  
  let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
  let context = CGContext(
    data: pixelData,
    width: Int(image.size.width),
    height: Int(image.size.height),
    bitsPerComponent: 8,
    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
    space: rgbColorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
  )
  
  context?.translateBy(x: 0, y: image.size.height)
  context?.scaleBy(x: 1.0, y: -1.0)
  
  UIGraphicsPushContext(context!)
  image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
  UIGraphicsPopContext()
  CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
  
  return pixelBuffer
}

private func appendPixelBufferForImage(
  _ image: CIImage,
  context: CIContext,
  pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor,
  presentationTime: CMTime
) -> Bool {
  /// at the beginning of the append the status is false
  var appendSucceeded = false
  
  /**
   *  The proccess of appending new pixels is put inside a autoreleasepool
   */
  autoreleasepool {
    // check posibilitty of creating a pixel buffer pool
    if let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
      let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
      let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
        kCFAllocatorDefault,
        pixelBufferPool,
        pixelBufferPointer
      )
      
      //        let _buffer = buffer(from: image)!
      
      /// check if the memory of the pixel buffer pointer can be accessed and the creation status is 0
      if let pixelBuffer = pixelBufferPointer.pointee,
         status == 0 {
        // if the condition is satisfied append the image pixels to the pixel buffer pool
        //        fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
        context.render(image, to: pixelBuffer)
        // generate new append status
        appendSucceeded = pixelBufferAdaptor.append(
          pixelBuffer,
          withPresentationTime: presentationTime
        )
        
        /**
         *  Destroy the pixel buffer contains
         */
        pixelBufferPointer.deinitialize(count: 1)
      } else {
        NSLog("error: Failed to allocate pixel buffer from pool")
      }
      
      /**
       Destroy the pixel buffer pointer from the memory
       */
      pixelBufferPointer.deallocate()
    }
  }
  
  return appendSucceeded
}

/*
 Private method to append pixels to a pixel buffer
 
 - parameter url:                The image which pixels will be appended to the pixel buffer
 - parameter pixelBufferAdaptor: The pixel buffer to which new pixels will be added
 - parameter presentationTime:   The duration of each frame of the video
 
 - returns: True or false depending on the action execution
 */
private func appendPixelBufferForImage(
  _ image: UIImage,
  pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor,
  presentationTime: CMTime
) -> Bool {
  /// at the beginning of the append the status is false
  var appendSucceeded = false
  
  /**
   *  The proccess of appending new pixels is put inside a autoreleasepool
   */
  autoreleasepool {
    // check posibilitty of creating a pixel buffer pool
    if let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
      let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
      let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
        kCFAllocatorDefault,
        pixelBufferPool,
        pixelBufferPointer
      )
      
      //        let _buffer = buffer(from: image)!
      
      /// check if the memory of the pixel buffer pointer can be accessed and the creation status is 0
      if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
        // if the condition is satisfied append the image pixels to the pixel buffer pool
        //        fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
        
        // generate new append status
        appendSucceeded = pixelBufferAdaptor
          .append(buffer(from: image)!, withPresentationTime: presentationTime)
        
        /**
         *  Destroy the pixel buffer contains
         */
        pixelBufferPointer.deinitialize(count: 1)
      } else {
        NSLog("error: Failed to allocate pixel buffer from pool")
      }
      
      /**
       Destroy the pixel buffer pointer from the memory
       */
      pixelBufferPointer.deallocate()
    }
  }
  
  return appendSucceeded
}

/**
 Private method to append image pixels to a pixel buffer
 
 - parameter image:       The image which pixels will be appented
 - parameter pixelBuffer: The pixel buffer (as memory) to which the image pixels will be appended
 */
private func fillPixelBufferFromImage(_ image: UIImage, pixelBuffer: CVPixelBuffer) {
  // lock the buffer memoty so no one can access it during manipulation
  CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
  
  // get the pixel data from the address in the memory
  let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
  
  // create a color scheme
  let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
  
  /// set the context size
  let contextSize = image.size
  
  // generate a context where the image will be drawn
  if let context = CGContext(
    data: pixelData,
    width: Int(contextSize.width),
    height: Int(contextSize.height),
    bitsPerComponent: 8,
    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
    space: rgbColorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
  ) {
    var imageHeight = image.size.height
    var imageWidth = image.size.width
    
    if Int(imageHeight) > context.height {
      imageHeight = 16 * (CGFloat(context.height) / 16).rounded(.awayFromZero)
    } else if Int(imageWidth) > context.width {
      imageWidth = 16 * (CGFloat(context.width) / 16).rounded(.awayFromZero)
    }
    
    let center = CGPoint.zero
    
    context.clear(CGRect(x: 0.0, y: 0.0, width: imageWidth, height: imageHeight))
    
    // set the context's background color
    context.setFillColor(UIColor.black.cgColor)
    context.fill(CGRect(x: 0.0, y: 0.0, width: CGFloat(context.width), height: CGFloat(context.height)))
    
    context.concatenate(.identity)
    
    // draw the image in the context
    
    if let cgImage = image.cgImage {
      context.draw(cgImage, in: CGRect(x: center.x, y: center.y, width: imageWidth, height: imageHeight))
    }
    
    // unlock the buffer memory
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
  }
}
