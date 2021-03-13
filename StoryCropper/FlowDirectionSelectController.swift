//
//  FlowDirectionSelectController.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 13.03.2021.
//

import UIKit

class FlowDirectionSelectController: BlurBackgroundController {
  
  let containerView = UIView()
  
  let titleLabel = UILabel()
  let segmentControl = UISegmentedControl(items: ["Left to right", "Right to left"])
  
  
  override func setupUI() {
    super.setupUI()
    
    contentView.addSubview(containerView)
    containerView.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.height.equalTo(250)
      make.leading.trailing.equalToSuperview().inset(32)
    }
    
    [titleLabel, segmentControl].forEach(contentView.addSubview)
    
    titleLabel.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(16)
      make.top.equalToSuperview().offset(8)
    }
  }
}
