//
//  File.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 10.03.2021.
//

import AVFoundation
import UIKit

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
