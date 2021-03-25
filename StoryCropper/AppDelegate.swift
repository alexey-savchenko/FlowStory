//
//  AppDelegate.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 14.01.2021.
//

import UIKit
import UNILibCore
import CombineUNILib
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  var mainCoordinator: MainModuleCoordinator!
  private var disposeBag = Set<AnyCancellable>()
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    window = UIWindow(frame: UIScreen.main.bounds)
    mainCoordinator = .init(window: window!)
    mainCoordinator
      .start()
      .sink(receiveValue: identity)
      .store(in: &disposeBag)
    
    return true
  }
}
