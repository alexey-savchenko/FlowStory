//
//  FlowSelectionCoordinator.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 15.03.2021.
//

import UNILibCore
import CombineUNILib
import UIKit
import Combine

class FlowSelectionCoordinator: BaseCoordinator<FlowDirection> {
  
  let presentationContext: PresentationContext
  let imageURL: URL
  
  init(imageURL: URL, presentationContext: PresentationContext) {
    self.imageURL = imageURL
    self.presentationContext = presentationContext
  }
  
  override func start() -> AnyPublisher<FlowDirection, Never> {
    let flowDirectionSelectController = FlowDirectionSelectController(imageURL: imageURL)
    flowDirectionSelectController.modalPresentationStyle = .overFullScreen
    presentationContext.present(flowDirectionSelectController, animated: true)
    
    return flowDirectionSelectController.confirmButton
      .publisher(for: .touchUpInside)
      .compactMap { [unowned flowDirectionSelectController] _ -> FlowDirection? in
        return FlowDirection(rawValue: flowDirectionSelectController.segmentControl.selectedSegmentIndex)
      }
      .do { [unowned presentationContext, unowned flowDirectionSelectController] _ in
        presentationContext.dismiss(flowDirectionSelectController, animated: true)
      }
      .eraseToAnyPublisher()
  }
}
