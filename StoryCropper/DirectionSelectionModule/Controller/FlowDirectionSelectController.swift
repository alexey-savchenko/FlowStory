//
//  FlowDirectionSelectController.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 13.03.2021.
//

import UIKit
import UNILib
import Combine

class FlowDirectionSelectController: BlurBackgroundController {
  
  let containerView = UIView()
  
  let contentStackView = UIStackView()
  let titleLabel = UILabel()
  let flowPreviewView = FlowPreviewView()
  let segmentControl = UISegmentedControl(items: ["Left to right", "Right to left"])
  let confirmButton = UIButton()
  
  override func setupUI() {
    super.setupUI()
    
    contentView.addSubview(containerView)
    containerView.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.leading.trailing.equalToSuperview().inset(32)
    }
    
    containerView.backgroundColor = .lightGray
    containerView.addSubview(contentStackView)
    contentStackView.axis = .vertical
    contentStackView.alignment = .center
    contentStackView.spacing = 16
    contentStackView.snp.makeConstraints { (make) in
      make.leading.top.equalToSuperview().offset(16)
      make.trailing.bottom.equalToSuperview().inset(16)
    }
    
    [titleLabel, flowPreviewView, segmentControl, confirmButton].forEach(contentStackView.addArrangedSubview)
    
    flowPreviewView.snp.makeConstraints { (make) in
      make.height.equalTo(100)
      make.leading.trailing.equalToSuperview().inset(16)
    }
    
    titleLabel.numberOfLines = 0
    titleLabel.attributedText = NSAttributedString(
      string: "Select video direction",
      attributes: [
        .foregroundColor: UIColor.white,
        .font: UIFont.systemFont(ofSize: 24, weight: .medium),
        .paragraphStyle: {
          let p = NSMutableParagraphStyle()
          p.alignment = .center
          return p
        }()
      ]
    )
    titleLabel.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(16)
    }
    
    segmentControl.snp.makeConstraints { (make) in
      make.leading.trailing.equalToSuperview().inset(16)
    }
    segmentControl.selectedSegmentIndex = 0
    
    confirmButton.layer.cornerRadius = 16
    confirmButton.backgroundColor = UIColor.orange
    confirmButton.clipsToBounds = true
    confirmButton.setAttributedTitle(
      NSAttributedString(
        string: "Confirm",
        attributes: [.foregroundColor: UIColor.white]
      ),
      for: .normal
    )
    confirmButton.snp.makeConstraints { (make) in
      make.height.equalTo(48)
      make.leading.trailing.equalToSuperview().inset(16)
    }
  }
}
