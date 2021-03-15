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
  let pickedURLPublisher = PassthroughSubject<URL, Never>()
  
  init(window: UIWindow) {
    self.window = window
  }
  
  override func start() -> AnyPublisher<Void, Never> {
    
    navigationController.setViewControllers([mainViewController], animated: false)
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
    
    mainViewController.addButton
      .publisher(for: .touchUpInside)
      .map(toVoid)
      .flatMap(requestAuthorization)
      .flatMap { _ -> AnyPublisher<URL, Never> in
        self.openPicker()
        return self.pickedURLPublisher.eraseToAnyPublisher()
      }
      .flatMap { url in
        return self.presentFlowDirectionSelection(
          presentationContext: ModalPresentationContext(
            presentingController: self.navigationController
          ),
          imageURL: url
        )
        .map { direction in
          return (url, direction)
        }
        .eraseToAnyPublisher()
      }
      .sink { url, direction in
        self.selectedVideoWith(url, flowDirection: direction)
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
  
  func presentFlowDirectionSelection(
    presentationContext: PresentationContext,
    imageURL: URL
  ) -> AnyPublisher<FlowDirection, Never> {
    let coordinator = FlowSelectionCoordinator(
      imageURL: imageURL,
      presentationContext: presentationContext
    )
    return coordinate(to: coordinator)
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
      pickedURLPublisher.send(videoURL)
    }
  }
  
  func selectedVideoWith(_ assetURL: URL, flowDirection: FlowDirection) {
    let sourceStream = makeFlowVideo(
      assetURL: assetURL,
      flowDirection: flowDirection
    )
    .share()
    
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
