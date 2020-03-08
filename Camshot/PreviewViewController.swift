//
//  PreviewViewController.swift
//  Camshot
//
//  Created by Timi Tejumola on 07/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit

class PreviewViewController: UIViewController {
    @IBOutlet weak var playerView: UIView!
    
    var videoUrl:  URL?
    var playPauseButton: PlayPauseButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = videoUrl else { return }
        
        let player = AVPlayer(url: url)
        player.rate = 1 //auto play
        player.isMuted = false
        let playerFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = playerFrame
        playerViewController.showsPlaybackControls = false

        addChild(playerViewController)
        playerView.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)

        playPauseButton = PlayPauseButton()
        playPauseButton.avPlayer = player
        playerView.addSubview(playPauseButton)
        playPauseButton.setup(in: self)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) {  _ in
            player.seek(to: CMTime.zero)
        }

    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        playPauseButton.updateUI()
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    

}
