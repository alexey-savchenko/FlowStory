//
//  FlowDirectionSelectController.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 13.03.2021.
//

import UIKit
import UNILibCore
import CombineUNILib
import Combine
import SnapKit

class FlowDirectionSelectController: DarkenBackgroundController {
  
  let containerView = UIView()
  
  let contentStackView = UIStackView()
  let titleLabel = UILabel()
  let flowPreviewView = FlowPreviewView()
  let segmentControl = UISegmentedControl(items: ["Left to right", "Right to left"])
  let confirmButton = UIButton()
  
  public var disposeBag = Set<AnyCancellable>()
  
  let imageURL: URL
  
  lazy var image: UIImage = {
    return UIImage(contentsOfFile: imageURL.path)!.fixedOrientation()!
  }()
  
  init(imageURL: URL) {
    self.imageURL = imageURL
    super.init(nibName: nil, bundle: nil)
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  fileprivate func setupContainerView() {
    containerView.layer.cornerRadius = 16
    containerView.clipsToBounds = true
    containerView.backgroundColor = .lightGray
    view.addSubview(containerView)
    containerView.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.leading.trailing.equalToSuperview().inset(32)
    }
    
    containerView.addSubview(contentStackView)
  }
  
  fileprivate func setupContentStackView() {
    contentStackView.axis = .vertical
    contentStackView.alignment = .center
    contentStackView.spacing = 16
    contentStackView.snp.makeConstraints { (make) in
      make.leading.top.equalToSuperview().offset(16)
      make.trailing.bottom.equalToSuperview().inset(16)
    }
    
    [titleLabel,
     flowPreviewView,
     segmentControl,
     confirmButton].forEach(contentStackView.addArrangedSubview)
  }
  
  fileprivate func setupFlowPreviewView() {
    flowPreviewView.snp.makeConstraints { (make) in
      make.height.equalTo(100)
      make.leading.trailing.equalToSuperview().inset(16)
    }
    
    flowPreviewView.backgroundImageView.image = image
  }
  
  fileprivate func setupTitleLabel() {
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
  }
  
  fileprivate func setupSegmentControl() {
    segmentControl.snp.makeConstraints { (make) in
      make.leading.trailing.equalToSuperview().inset(16)
    }
    segmentControl.selectedSegmentIndex = 0
  }
  
  fileprivate func setupConfirmButton() {
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
  
  override func setupUI() {
    super.setupUI()
        
    setupContainerView()
    setupContentStackView()
    setupFlowPreviewView()
    setupTitleLabel()
    setupSegmentControl()
    setupConfirmButton()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    segmentControl
      .publisher(for: .valueChanged)
      .compactMap { [unowned segmentControl] _ -> FlowDirection? in
        return FlowDirection(rawValue: segmentControl.selectedSegmentIndex)
      }
      .sink { [unowned self] (direction) in
        self.flowPreviewView.set(direction: direction)
      }
      .store(in: &disposeBag)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    self.flowPreviewView.set(direction: .leftToRight)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    let imageHeightRatio = image.size.height / image.size.width
    flowPreviewView.snp.updateConstraints { (make) in
      make.height.equalTo(flowPreviewView.frame.width * imageHeightRatio)
    }
  }
}
