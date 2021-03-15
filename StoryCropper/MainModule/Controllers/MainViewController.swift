//
//  ViewController.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 14.01.2021.
//

import UIKit
import Photos
import MobileCoreServices
import Combine
import UNILib
import SnapKit

class MainViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CAAnimationDelegate {
  
  enum State: Hashable {
    case initial
    case rendering(progress: Double)
    case rendered(url: URL)
  }
  
  let addButton = UIButton()
  let circularProgressBarView = CircularProgressBarView()
  
  lazy var progressBarDismissAnimation: CAAnimation = {
    let animation0 = CABasicAnimation(keyPath: "opacity")
    let animation1 = CABasicAnimation(keyPath: "transform")
    
    animation0.fromValue = 1
    animation0.toValue = 0
    
    animation1.fromValue = CATransform3DIdentity
    animation1.toValue = CATransform3DMakeScale(5, 5, 1)
    
    let animationgroup = CAAnimationGroup()
    animationgroup.animations = [animation0, animation1]
    animationgroup.duration = 0.5
    animationgroup.delegate = self
    return animationgroup
  }()
  
  lazy var progressBarRotationAnimation: CAAnimation = {
    let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
    rotationAnimation.fromValue = 0
    rotationAnimation.toValue = Double.pi * 2
    rotationAnimation.duration = 2
    rotationAnimation.repeatCount = .infinity
    return rotationAnimation
  }()
  
  let playerView = PlayerView(player: AVPlayer())
  let shareStackView = UIStackView()
  let instagramShareButton = UIButton()
  let shareButton = UIButton()
  let infoLabel = UILabel()
  let maskLayer = CAGradientLayer()
  
  var lastExportedURL: URL?
  var playerObservationToken: Any?
  
  var stackViewBottomConstraint: ConstraintMakerEditable?
  
  let state = CurrentValueSubject<State, Never>.init(.initial)

  private var disposeBag = Set<AnyCancellable>()
  
  fileprivate func setupPlayerView() {
    playerView.isHidden = true
    playerView.playerLayer.videoGravity = .resizeAspectFill
    playerView.clipsToBounds = true
    playerView.layer.mask = maskLayer
    
    playerView.snp.makeConstraints { (make) in
      make.leading.bottom.trailing.equalToSuperview()
      make.top.equalTo(circularProgressBarView)
    }
  }
  
  fileprivate func setupShareStackView() {
    
    shareStackView.snp.makeConstraints { (make) in
      self.stackViewBottomConstraint = make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-16)
      make.centerX.equalToSuperview()
    }
    
    [instagramShareButton, shareButton].forEach {
      $0.layer.cornerRadius = 16
      $0.backgroundColor = UIColor.orange
      $0.clipsToBounds = true
      shareStackView.addArrangedSubview($0)
      $0.snp.makeConstraints { (make) in
        make.height.equalTo(48)
      }
    }
    
    instagramShareButton.setTitle("Instagram", for: .normal)
    shareButton.setTitle("Export", for: .normal)
    
    instagramShareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    
    shareStackView.axis = .horizontal
    shareStackView.spacing = 24
    shareStackView.alignment = .center
    shareStackView.alpha = 0
    
    instagramShareButton.addTarget(self, action: #selector(shareToInstagram), for: .touchUpInside)
    shareButton.addTarget(self, action: #selector(openIn), for: .touchUpInside)
  }
  
  fileprivate func setupInfoLabel() {
    infoLabel.snp.makeConstraints { (make) in
      make.center.equalTo(circularProgressBarView)
    }
    infoLabel.attributedText = .init(
      string: "Rendering...",
      attributes: [.font: UIFont.boldSystemFont(ofSize: 32),
                   .foregroundColor: UIColor.white]
    )
    infoLabel.alpha = 0
  }
  
  fileprivate func setupAddButton() {
    addButton.snp.makeConstraints { (make) in
      make.center.equalTo(circularProgressBarView)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(250)
    }
    addButton.setAttributedTitle(
      .init(
        string: "Select photo",
        attributes: [.font: UIFont.boldSystemFont(ofSize: 32),
                     .foregroundColor: UIColor.white]
      ),
      for: .normal
    )
  }
  
  fileprivate func setupProgressBarView() {
    circularProgressBarView.snp.makeConstraints { (make) in
      make.size.equalTo(250)
      make.center.equalToSuperview()
    }
    circularProgressBarView.progress = 0
    circularProgressBarView.progressLayer.add(progressBarRotationAnimation, forKey: "rotationAnimation")
  }
  
  fileprivate func setupUI() {
    
    maskLayer.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.cgColor]
    view.backgroundColor = .lightGray
    navigationController?.setNavigationBarHidden(true, animated: false)
    
    [
      playerView,
      circularProgressBarView,
      addButton,
      infoLabel,
      shareStackView,
    ]
    .forEach(view.addSubview)
    
    setupProgressBarView()
    setupAddButton()
    setupInfoLabel()
    setupShareStackView()
    setupPlayerView()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    
    try! FileManager.default.contentsOfDirectory(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
      .forEach {
        try? FileManager.default.removeItem(atPath: $0)
      }
    
    playerObservationToken = playerView.player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: nil) { [unowned playerView] (time) in
      if time == playerView.player.currentItem?.duration {
        playerView.player.seek(to: .zero)
        playerView.player.play()
      }
    }
    
    state
      .sink(receiveValue: { [weak self] state in self?.render(state: state) })
      .store(in: &disposeBag)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    maskLayer.frame = playerView.bounds
  }
  
  @objc func shareToInstagram() {
    if let asset = lastPHAssetInCameraRoll() {
      let url = URL(string: "instagram://library?OpenInEditor=1&LocalIdentifier=\(asset.localIdentifier)")!
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
      }
    }
  }
  
  @objc func openIn() {
    let c = UIActivityViewController(activityItems: [lastExportedURL!], applicationActivities: nil)
    self.present(c, animated: true)
  }

  func render(state: State) {
    playerView.isHidden = true
    infoLabel.alpha = 0
    addButton.alpha = 0
    shareStackView.alpha = 0
    circularProgressBarView.layer.opacity = 0
    
    switch state {
    case .initial:
      addButton.alpha = 1
      addButton.setAttributedTitle(
        .init(
          string: "Select photo",
          attributes: [.font: UIFont.boldSystemFont(ofSize: 32),
                       .foregroundColor: UIColor.white]
        ),
        for: .normal
      )
    case .rendered(let url):
      lastExportedURL = url
      infoLabel.alpha = 0
      animateProgressBarDismiss()
      addButton.alpha = 1
      playerView.isHidden = false
      addButton.setAttributedTitle(
        .init(
          string: "Select another photo",
          attributes: [.font: UIFont.boldSystemFont(ofSize: 32),
                       .foregroundColor: UIColor.white]
        ),
        for: .normal
      )
      playerView.player.replaceCurrentItem(with: .init(url: url))
      playerView.player.play()
      stackViewBottomConstraint?.constraint.update(offset: -16)
      UIView.animate(withDuration: 0.3) {
        self.shareStackView.alpha = 1
        self.view.layoutIfNeeded()
      }
      
    case .rendering(let progress):
      playerView.isHidden = true
      infoLabel.alpha = 1
      stackViewBottomConstraint?.constraint.update(offset: 16)
      view.layoutIfNeeded()
      addButton.alpha = 0
      shareStackView.alpha = 0
      circularProgressBarView.layer.opacity = 1

      self.circularProgressBarView.progress = progress
    }
  }
  
  func animateProgressBarDismiss() {
    circularProgressBarView.layer.opacity = 0
    circularProgressBarView.layer.add(progressBarDismissAnimation, forKey: "dismissAnimation")
  }
  
  func lastPHAssetInCameraRoll() -> PHAsset? {
    let ops = PHFetchOptions()
    ops.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let fetchResult = PHAsset.fetchAssets(with: .video, options: ops)
    var phAssets = [PHAsset]()
    fetchResult.enumerateObjects { asset, idx, _ in
      phAssets.append(asset)
    }
    let lastAsset = phAssets.first
    return lastAsset
  }
  
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    if anim == progressBarDismissAnimation {
      circularProgressBarView.progress = 0
    }
  }
}
