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

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CAAnimationDelegate {
  
  let addButton = UIButton()
  let circularProgressBarView = CircularProgressBarView()
  
  let playerView = PlayerView(player: AVPlayer())
  let shareStackView = UIStackView()
  let instagramShareButton = UIButton()
  let shareButton = UIButton()
  let infoLabel = UILabel()
  let maskLayer = CAGradientLayer()
  
  var lastExportedURL: URL?
  var playerObservationToken: Any?
  
  lazy var stackViewBottomConstraint: NSLayoutConstraint = {
    return shareStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
  }()

  private var disposeBag = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .lightGray
    
    try! FileManager.default.contentsOfDirectory(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
      .forEach {
        try? FileManager.default.removeItem(atPath: $0)
      }
    navigationController?.setNavigationBarHidden(true, animated: false)
    
    [
      circularProgressBarView,
      addButton,
      infoLabel,
      playerView,
      shareStackView,
    ]
    .forEach {
      view.addSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
      
    NSLayoutConstraint.activate(
      [
        circularProgressBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        circularProgressBarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        circularProgressBarView.widthAnchor.constraint(equalToConstant: 250),
        circularProgressBarView.heightAnchor.constraint(equalToConstant: 250),
        addButton.centerXAnchor.constraint(equalTo: circularProgressBarView.centerXAnchor),
        addButton.centerYAnchor.constraint(equalTo: circularProgressBarView.centerYAnchor),
        stackViewBottomConstraint,
        shareStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        infoLabel.centerXAnchor.constraint(equalTo: circularProgressBarView.centerXAnchor),
        infoLabel.centerYAnchor.constraint(equalTo: circularProgressBarView.centerYAnchor),
        playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        playerView.heightAnchor.constraint(equalToConstant: 250)
      ]
    )
    circularProgressBarView.progress = 0
    addButton.setAttributedTitle(
      .init(
        string: "Select photo",
        attributes: [.font: UIFont.boldSystemFont(ofSize: 32),
                     .foregroundColor: UIColor.white]
      ),
      for: .normal
    )
    addButton.addTarget(self, action: #selector(openPicker), for: .touchUpInside)
    infoLabel.attributedText = .init(
      string: "Rendering...",
      attributes: [.font: UIFont.boldSystemFont(ofSize: 32),
                   .foregroundColor: UIColor.white]
    )
    infoLabel.alpha = 0
    
    [instagramShareButton, shareButton].forEach {
      $0.layer.cornerRadius = 16
      $0.layer.borderWidth = 2
      $0.layer.borderColor = UIColor.orange.cgColor
      shareStackView.addArrangedSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate(
        [
          $0.heightAnchor.constraint(equalToConstant: 48),
        ]
      )
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
    
    playerView.isHidden = true
    playerView.playerLayer.videoGravity = .resizeAspectFill
    playerView.clipsToBounds = true
    playerView.layer.mask = maskLayer
    playerObservationToken = playerView.player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: nil) { [unowned playerView] (time) in
      if time == playerView.player.currentItem?.duration {
        playerView.player.seek(to: .zero)
        playerView.player.play()
      }
    }
    
    maskLayer.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.cgColor]
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
  
  @objc func openPicker() {
    requestAuthorization {
      DispatchQueue.main.async {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeImage as String]
        picker.delegate = self
        picker.allowsEditing = false
        self.present(picker, animated: true)
      }
    }
  }
  
  func imagePickerControllerDidCancel(
    _ picker: UIImagePickerController
  ) {
    picker.dismiss(animated: true)
  }
  
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    picker.dismiss(animated: true)
    if let videoURL = info[.imageURL] as? URL {
      selectedVideoWith(videoURL)
    }
  }
  
  func selectedVideoWith(_ assetURL: URL) {
    playerView.isHidden = true
    infoLabel.alpha = 1
    stackViewBottomConstraint.constant = 16
    addButton.alpha = 0
    shareStackView.alpha = 0
    circularProgressBarView.layer.opacity = 1
    let sourceStream = makeFlowVideo(assetURL: assetURL).share()

    sourceStream
      .compactMap { $0.right }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] progress in
        self?.circularProgressBarView.progress = progress
      }
      .store(in: &disposeBag)
    
    sourceStream
      .compactMap { $0.left }
      .map { asset in return (asset as! AVURLAsset).url }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] url in
        self?.lastExportedURL = url
        self?.infoLabel.alpha = 0
        self?.animateProgressBarDismiss()
        self?.addButton.alpha = 1
        self?.addButton.setAttributedTitle(
          .init(
            string: "Select another photo",
            attributes: [.font: UIFont.boldSystemFont(ofSize: 32),
                         .foregroundColor: UIColor.white]
          ),
          for: .normal
        )
        if let error = self?.saveVideoToAlbum(url) {
          self?.presentSystemAlert(error: error)
        } else {
          self?.playerView.isHidden = false
          self?.playerView.player.replaceCurrentItem(with: .init(url: url))
          self?.playerView.player.play()
          self?.stackViewBottomConstraint.constant = -16
          UIView.animate(withDuration: 0.3) {
            self?.shareStackView.alpha = 1
            self?.view.layoutIfNeeded()
          }
        }
      }
      .store(in: &disposeBag)
  }
  
  func animateProgressBarDismiss() {
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
    
    circularProgressBarView.layer.opacity = 0
    circularProgressBarView.layer.add(animationgroup, forKey: nil)
  }
  
  func requestAuthorization(completion: @escaping () -> Void) {
    if PHPhotoLibrary.authorizationStatus() == .authorized {
      completion()
    } else {
      PHPhotoLibrary.requestAuthorization { (status) in
        completion()
      }
    }
  }
  
  func saveVideoToAlbum(_ outputURL: URL) -> Error? {
    do {
      try PHPhotoLibrary.shared().performChangesAndWait {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
      }
      return nil
    } catch {
      return error
    }
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
    circularProgressBarView.progress = 0
  }
}
