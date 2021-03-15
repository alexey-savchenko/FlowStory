//
//  BlurBackgroundController.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 13.03.2021.
//

import UIKit

open class DarkenBackgroundController: UIViewController {
    
  open func setupUI() {

  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
  }
  
  func animateLighten() {
    UIView.animate(withDuration: 0.5) {
      self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    }
  }
  
  func animateDarken() {
    UIView.animate(withDuration: 0.5) {
      self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    }
  }
  
  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    animateDarken()
  }
}
