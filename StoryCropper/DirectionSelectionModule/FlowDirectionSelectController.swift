//
//  FlowDirectionSelectController.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 13.03.2021.
//

import UIKit
import UNILib
import Combine

enum FlowDirection: Int, Hashable {
  case leftToRight
  case rightToLeft
}

class FlowSelectionCoordinator: BaseCoordinator<FlowDirection> {
  
  let presentationContext: PresentationContext
  
  internal init(presentationContext: PresentationContext) {
    self.presentationContext = presentationContext
  }
  
  override func start() -> AnyPublisher<FlowDirection, Never> {
    let c = FlowDirectionSelectController()
    presentationContext.present(c, animated: true)
    return c.resultSubject
      .do { [unowned presentationContext, unowned c] _ in
        presentationContext.dismiss(c, animated: true)
      }
      .eraseToAnyPublisher()
  }
}

class FlowDirectionSelectController: BlurBackgroundController {
  
  let containerView = UIView()
  
  let titleLabel = UILabel()
  let segmentControl = UISegmentedControl(items: ["Left to right", "Right to left"])
  let confirmButton = UIButton()
  
  let resultSubject = PassthroughSubject<FlowDirection, Never>()
  
  override func setupUI() {
    super.setupUI()
    
    contentView.addSubview(containerView)
    containerView.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.height.equalTo(250)
      make.leading.trailing.equalToSuperview().inset(32)
    }
    
    [titleLabel, segmentControl, confirmButton].forEach(contentView.addSubview)
    
    titleLabel.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(16)
      make.top.equalToSuperview().offset(8)
    }
    
    segmentControl.snp.makeConstraints { (make) in
      make.leading.trailing.equalToSuperview().inset(16)
      make.bottom.equalTo(confirmButton.snp.top).inset(16)
    }
    
    confirmButton.snp.makeConstraints { (make) in
      make.height.equalTo(48)
      make.bottom.equalToSuperview().inset(16)
      make.centerX.equalToSuperview()
    }
    
    confirmButton.addTarget(self, action: #selector(confirmTap), for: .touchUpInside)
  }
  
  @objc private func confirmTap() {
    resultSubject.send(FlowDirection(rawValue: segmentControl.selectedSegmentIndex)!)
  }
}
