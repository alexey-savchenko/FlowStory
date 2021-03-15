//
//  FlowPreviewView.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 15.03.2021.
//

import UIKit
import UNILib

class FlowPreviewView: UIView {
  
  let frameLayer = CALayer()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupUI()
  }
  
  var leftBoundaryRect: CGRect {
    return CGRect(x: 0, y: 0, width: bounds.height * 0.5625, height: bounds.height)
  }
  
  var rightBoundaryRect: CGRect {
    return CGRect(x: bounds.width - bounds.height * 0.5625, y: 0, width: bounds.height * 0.5625, height: bounds.height)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    backgroundColor = .orange
    
    layer.addSublayer(frameLayer)
    clipsToBounds = true
    frameLayer.backgroundColor = UIColor.cyan.withAlphaComponent(0.2).cgColor
    frameLayer.borderWidth = 2
    frameLayer.borderColor = UIColor.cyan.cgColor
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    frameLayer.frame = leftBoundaryRect
  }
  
  func set(direction: FlowDirection) {
    frameLayer.removeAnimation(forKey: "translationAnimation")
    
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 2
    animation.repeatCount = .infinity
    switch direction {
    case .leftToRight:
      animation.fromValue = CGPoint(x: leftBoundaryRect.midX, y: leftBoundaryRect.midY)
      animation.toValue = CGPoint(x: rightBoundaryRect.midX + rightBoundaryRect.width, y: rightBoundaryRect.midY)
    case .rightToLeft:
      animation.fromValue = CGPoint(x: rightBoundaryRect.midX, y: rightBoundaryRect.midY)
      animation.toValue = CGPoint(x: leftBoundaryRect.midX - leftBoundaryRect.width, y: leftBoundaryRect.midY)
    }
    
    frameLayer.add(animation, forKey: "translationAnimation")
  }
}
