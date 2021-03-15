//
//  BlurBackgroundController.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 13.03.2021.
//

import UIKit

open class BlurBackgroundController: UIViewController {
  
  let visualEffectView = UIVisualEffectView()
  let visualEffect: UIVisualEffect
  
  var contentView: UIView {
    return visualEffectView.contentView
  }
  
  init(visualEffect: UIVisualEffect = UIBlurEffect(style: .prominent)) {
    self.visualEffect = visualEffect
    super.init(nibName: nil, bundle: nil)
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open func setupUI() {
    view.addSubview(visualEffectView)
    visualEffectView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
  }
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    UIView.animate(withDuration: 0.5) {
      self.visualEffectView.effect = self.visualEffect
    }
  }
}
