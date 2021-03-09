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

class PlayerView: UIView {
  
  let player: AVPlayer
  
  lazy var gesture: UITapGestureRecognizer = {
    return UITapGestureRecognizer(target: self, action: #selector(restartPlayer))
  }()
  
  init(player: AVPlayer) {
    self.player = player
    super.init(frame: .zero)
    
    playerLayer.player = player
    isUserInteractionEnabled = true
    addGestureRecognizer(gesture)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var playerLayer: AVPlayerLayer {
    return layer as! AVPlayerLayer
  }
  
  override class var layerClass: AnyClass {
    return AVPlayerLayer.self
  }
  
  @objc func restartPlayer() {
    player.seek(to: .zero)
    player.play()
  }
}

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  
  lazy var addButtonItem: UIBarButtonItem = {
    return UIBarButtonItem(
      title: "Add",
      style: .done,
      target: self,
      action: #selector(openPicker)
    )
  }()
  
  let player = AVPlayer()
  lazy var playerView: PlayerView = {
    return PlayerView(player: player)
  }()
  let progressBar = UIProgressView(progressViewStyle: .bar)
  
  var token: Any?
  
  private var disposeBag = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    try! FileManager.default.contentsOfDirectory(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
      .forEach {
        try? FileManager.default.removeItem(atPath: $0)
      }
    
    navigationItem.rightBarButtonItems = [addButtonItem]
    [playerView, progressBar].forEach(view.addSubview)
    playerView.translatesAutoresizingMaskIntoConstraints = false
    progressBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate(
      [
        progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        progressBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        playerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
      ]
    )
    
    token = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 60), queue: nil) { (time) in
      if let duration = self.player.currentItem?.duration.seconds {
        self.progressBar.progress = Float(time.seconds / duration)
      }
    }
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
    makeFlowVideo1(assetURL: assetURL)
      .map { asset in return (asset as! AVURLAsset).url }
      .sink { url in
        if let error = self.saveVideoToAlbum(url) {
          print(error)
        } else {
          print("success")
        }
        
      }
      .store(in: &disposeBag)
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
}
