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

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  
  let addButton = UIButton()
  let circularProgressBarView = CircularProgressBarView()

  private var disposeBag = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .lightGray
    
    try! FileManager.default.contentsOfDirectory(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
      .forEach {
        try? FileManager.default.removeItem(atPath: $0)
      }
    navigationController?.setNavigationBarHidden(true, animated: false)

    [circularProgressBarView, addButton]
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
      ]
    )
    circularProgressBarView.progress = 0
    addButton.setTitle("Select Photo", for: .normal)
    addButton.addTarget(self, action: #selector(openPicker), for: .touchUpInside)
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
    addButton.isHidden = true
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
        self?.circularProgressBarView.progress = 0
        self?.animateProgressBarDismiss()
        self?.addButton.isHidden = false
        if let error = self?.saveVideoToAlbum(url) {
          self?.presentSystemAlert(error: error)
        } else {
          print("success")
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
}
