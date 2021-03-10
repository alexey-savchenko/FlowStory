//
//  CircularProgressBarView.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 10.03.2021.
//

import Foundation
import UIKit

class CircularProgressBarView: UIView {
  
  let trackLayer = CAShapeLayer()
  let progressLayer = CAShapeLayer()
  
  var progress: Double = 0 {
    didSet {
      drawProgress()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    [trackLayer, progressLayer].forEach(layer.addSublayer)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    [trackLayer, progressLayer].forEach {
      $0.frame = bounds
    }
  }
  
  func drawProgress() {
    
    let maxTrackWidth: CGFloat = 32
    let minTrackWidth: CGFloat = 8
    let actualTrackWidth = maxTrackWidth + ((1.0 - CGFloat(progress)) * (minTrackWidth - maxTrackWidth))
//      maxTrackWidth - ((1.0 - CGFloat(progress)) * minTrackWidth)
    
    let trackPath = UIBezierPath(ovalIn: bounds)
    trackLayer.lineWidth = actualTrackWidth
    trackLayer.strokeColor = UIColor.lightGray.cgColor
    trackLayer.path = trackPath.cgPath
    trackLayer.fillColor = UIColor.clear.cgColor
    
    progressLayer.lineWidth = actualTrackWidth
    progressLayer.lineCap = .round
    
    let startColor = (r: 255.0 / 255.0, g: 147.0 / 255.0, b: 0 / 255.0)
    let endColor = (r: 89.0 / 255.0, g: 245.0 / 255.0, b: 118.0 / 255.0)
    
    let currentColor = UIColor(
      red: CGFloat((1 - progress) * startColor.r + progress * endColor.r),
      green: CGFloat((1 - progress) * startColor.g + progress * endColor.g),
      blue: CGFloat((1 - progress) * startColor.b + progress * endColor.b),
      alpha: 1
    )
    
    progressLayer.path = trackPath.cgPath
    progressLayer.strokeColor = currentColor.cgColor
    progressLayer.fillColor = UIColor.clear.cgColor
    progressLayer.strokeEnd = CGFloat(progress)
  }
}
