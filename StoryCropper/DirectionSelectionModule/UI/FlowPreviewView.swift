//
//  FlowPreviewView.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 15.03.2021.
//

import UIKit
import UNILib

class FlowPreviewView: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    backgroundColor = .orange
  }
  
}
