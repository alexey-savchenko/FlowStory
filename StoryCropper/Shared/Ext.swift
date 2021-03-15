//
//  Ext.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 27.02.2021.
//

import UIKit
import AVFoundation
import CoreImage

infix operator >>>:
func >>> (lhs: CIImage, rhs: (CGSize, CGPoint)) -> CIImage {
  let transform =
    CGAffineTransform.identity
    .concatenating(.init(scaleX: rhs.0.width, y: rhs.0.height))
    .concatenating(.init(translationX: rhs.1.x, y: rhs.1.y))
  return lhs.transformed(by: transform)
}

public func scaleAndPositionInAspectFillMode(_ inputSize: CGSize, in area: CGSize) -> (scale: CGSize, position: CGPoint) {
  let assetSize = inputSize
  let aspectFillSize = CGSize.aspectFill(videoSize: assetSize, boundingSize: area)
  let aspectFillScale = CGSize(width: aspectFillSize.width / assetSize.width, height: aspectFillSize.height / assetSize.height)
  let position = CGPoint(x: (area.width - aspectFillSize.width) / 2.0, y: (area.height - aspectFillSize.height) / 2.0)
  return (scale: aspectFillScale, position: position)
}

public func scaleAndPositionInAspectFitMode(_ inputSize: CGSize, in area: CGSize) -> (scale: CGSize, position: CGPoint) {
  let assetSize = inputSize
  let aspectFitSize = CGSize.aspectFit(videoSize: assetSize, boundingSize: area)
  let aspectFitScale = CGSize(width: aspectFitSize.width / assetSize.width, height: aspectFitSize.height / assetSize.height)
  let position = CGPoint(x: (area.width - aspectFitSize.width) / 2.0, y: (area.height - aspectFitSize.height) / 2.0)
  return (scale: aspectFitScale, position: position)
}

extension CGSize {
  
  func rounded(rule: FloatingPointRoundingRule) -> CGSize {
    return .init(width: width.rounded(rule), height: height.rounded(rule))
  }
  
  func flipped() -> CGSize {
    .init(width: height, height: width)
  }
  
  func squareValue() -> CGFloat {
    return width * height
  }
  
  static func aspectFit(videoSize: CGSize, boundingSize: CGSize) -> CGSize {
    var size = boundingSize
    let mW = boundingSize.width / videoSize.width
    let mH = boundingSize.height / videoSize.height
    
    if mH < mW {
      size.width = boundingSize.height / videoSize.height * videoSize.width
    } else if mW < mH {
      size.height = boundingSize.width / videoSize.width * videoSize.height
    }
    
    return size
  }
  
  static func aspectFill(videoSize: CGSize, boundingSize: CGSize) -> CGSize {
    var size = boundingSize
    let mW = boundingSize.width / videoSize.width
    let mH = boundingSize.height / videoSize.height
    
    if mH > mW {
      size.width = boundingSize.height / videoSize.height * videoSize.width
    } else if mW > mH {
      size.height = boundingSize.width / videoSize.width * videoSize.height
    }
    
    return size
  }
}

func greatestCommonDivisor(a: Int, b: Int) -> Int {
  if a == b {
    return a
  } else {
    return a > b ?
      greatestCommonDivisor(a: a - b, b: b) :
      greatestCommonDivisor(a: a, b: b - a)
  }
}

extension CGSize: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(width)
    hasher.combine(height)
  }
}

extension CGSize: Comparable {
  public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
    return (lhs.width * lhs.height) < (rhs.width * rhs.height)
  }
}

// MARK: - Image Scaling.
extension UIImage {
  
  func fixedOrientation() -> UIImage? {
    guard imageOrientation != UIImage.Orientation.up else {
      // This is default orientation, don't need to do anything
      return self.copy() as? UIImage
    }

    guard let cgImage = self.cgImage else {
      // CGImage is not available
      return nil
    }

    guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(
      data: nil,
      width: Int(size.width),
      height: Int(size.height),
      bitsPerComponent: cgImage.bitsPerComponent,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil // Not able to create CGContext
    }

    var transform: CGAffineTransform = CGAffineTransform.identity

    switch imageOrientation {
    case .down, .downMirrored:
      transform = transform.translatedBy(x: size.width, y: size.height)
      transform = transform.rotated(by: CGFloat.pi)
    case .left, .leftMirrored:
      transform = transform.translatedBy(x: size.width, y: 0)
      transform = transform.rotated(by: CGFloat.pi / 2.0)
    case .right, .rightMirrored:
      transform = transform.translatedBy(x: 0, y: size.height)
      transform = transform.rotated(by: CGFloat.pi / -2.0)
    case .up, .upMirrored:
      break
    @unknown default:
      break
    }

    // Flip image one more time if needed to, this is to prevent flipped image
    switch imageOrientation {
    case .upMirrored, .downMirrored:
      transform = transform.translatedBy(x: size.width, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    case .leftMirrored, .rightMirrored:
      transform = transform.translatedBy(x: size.height, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    case .up, .down, .left, .right:
      break
    @unknown default:
      break
    }

    ctx.concatenate(transform)

    switch imageOrientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
    default:
      ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }

    guard let newCGImage = ctx.makeImage() else { return nil }
    return UIImage(cgImage: newCGImage, scale: 1, orientation: .up)
  }
  
  /// Represents a scaling mode
  enum ScalingMode {
    case aspectFill
    case aspectFit
    
    /// Calculates the aspect ratio between two sizes
    ///
    /// - parameters:
    ///     - size:      the first size used to calculate the ratio
    ///     - otherSize: the second size used to calculate the ratio
    ///
    /// - return: the aspect ratio between the two sizes
    func aspectRatio(between size: CGSize, and otherSize: CGSize) -> CGFloat {
      let aspectWidth = size.width / otherSize.width
      let aspectHeight = size.height / otherSize.height
      
      switch self {
      case .aspectFill:
        return max(aspectWidth, aspectHeight)
      case .aspectFit:
        return min(aspectWidth, aspectHeight)
      }
    }
  }
  
  /// Scales an image to fit within a bounds with a size governed by the passed size. Also keeps the aspect ratio.
  ///
  /// - parameter:
  ///     - newSize:     the size of the bounds the image must fit within.
  ///     - scalingMode: the desired scaling mode
  ///
  /// - returns: a new scaled image.
  func scaled(to newSize: CGSize, scalingMode: UIImage.ScalingMode = .aspectFill) -> UIImage {
    let aspectRatio = scalingMode.aspectRatio(between: newSize, and: size)
    
    /* Build the rectangle representing the area to be drawn */
    var scaledImageRect = CGRect.zero
    
    scaledImageRect.size.width = size.width * aspectRatio
    scaledImageRect.size.height = size.height * aspectRatio
    scaledImageRect.origin.x = (newSize.width - size.width * aspectRatio) / 2.0
    scaledImageRect.origin.y = (newSize.height - size.height * aspectRatio) / 2.0
    
    /* Draw and retrieve the scaled image */
    UIGraphicsBeginImageContext(newSize)
    
    draw(in: scaledImageRect)
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return scaledImage!
  }
}


extension FloatingPoint {
  public func rounded2(toPlaces places: Int) -> Self {
    guard places >= 0 else { return self }
    let divisor = Self(Int(pow(10.0, Double(places))))
    return (self * divisor).rounded() / divisor
  }
  
  func rounded(toDividingEvenlyTo divisor: Self) -> Self {
    var result = self.rounded(.toNearestOrEven)
    while result.truncatingRemainder(dividingBy: divisor) != 0 {
      result += 1
    }
    return result
  }
  
  func clamped(min: Self, max: Self) -> Self {
    if self < min {
      return min
    } else if self > max {
      return max
    } else {
      return self
    }
  }
}

public extension UIViewController {
  func presentSystemAlert(error: Error, completion: ((UIAlertAction) -> Void)? = nil) {
    
    let alert = UIAlertController(
      title: "Error",
      message: error.localizedDescription,
      preferredStyle: .alert
    )
    alert.addAction(
      UIAlertAction(
        title: "OK",
        style: .default,
        handler: completion
      )
    )
    self.present(alert, animated: true)
    
  }
}
