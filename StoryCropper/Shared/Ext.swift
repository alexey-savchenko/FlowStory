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

extension CGSize: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(width)
    hasher.combine(height)
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
