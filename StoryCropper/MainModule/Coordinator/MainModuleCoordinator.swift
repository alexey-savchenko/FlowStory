//
//  MainModuleCoordinator.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 15.03.2021.
//

import UNILib
import UIKit
import Combine
import Photos
import MobileCoreServices

class MainModuleCoordinator: BaseCoordinator<Void>, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  
  let window: UIWindow
  let navigationController = UINavigationController()
  let mainViewController = MainViewController()
  private var disposeBag = Set<AnyCancellable>()
  
  init(window: UIWindow) {
    self.window = window
  }
  
  override func start() -> AnyPublisher<Void, Never> {
    
    navigationController.setViewControllers([mainViewController], animated: false)
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
    
    mainViewController.addButton
      .publisher(for: .touchUpInside)
      .do { _ in print("!!!") }
      .map(toVoid)
      .flatMap(requestAuthorization)
      .sink {
        self.openPicker()
      }
      .store(in: &disposeBag)
    
    return Just(Void()).ignoreOutput().eraseToAnyPublisher()
  }
  
  private func openPicker() {
    let picker = UIImagePickerController()
    picker.mediaTypes = [kUTTypeImage as String]
    picker.delegate = self
    picker.allowsEditing = false
    navigationController.present(picker, animated: true)
  }
  
  func requestAuthorization() -> AnyPublisher<Void, Never> {
    return Future { promise in
      
      if PHPhotoLibrary.authorizationStatus() == .authorized {
        promise(.success(Void()))
      } else {
        PHPhotoLibrary.requestAuthorization { (status) in
          promise(.success(Void()))
        }
      }
    }
    .eraseToAnyPublisher()
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
    let sourceStream = makeFlowVideo(assetURL: assetURL).share()

    sourceStream
      .compactMap { $0.right }
      .receive(on: DispatchQueue.main)
      .map(MainViewController.State.rendering(progress:))
      .do { value in print(value) } 
      .subscribe(mainViewController.state)
      .store(in: &disposeBag)

    sourceStream
      .compactMap { $0.left }
      .map { asset in return (asset as! AVURLAsset).url }
      .receive(on: DispatchQueue.main)
      .do { url in
        let _ = self.saveVideoToAlbum(url)
      }
      .map(MainViewController.State.rendered(url:))
      .subscribe(mainViewController.state)
      .store(in: &disposeBag)
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
