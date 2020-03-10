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
import Firebase
import SVProgressHUD

class PreviewViewController: UIViewController {
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var actionBar: UIView!

    var videoUrl:  URL?
    var playPauseButton: PlayPauseButton!
    var originalImage: UIImage?
    var filteredImage: CIImage?
    var selectedFilter: String?

    var CIFilterNames = [
        "CIVibrance",
        "CIPhotoEffectChrome",
        "CIPhotoEffectFade",
        "CIPhotoEffectInstant",
        "CIPhotoEffectNoir",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTonal",
        "CIPhotoEffectTransfer",
        "CISepiaTone",
        "CILinearToSRGBToneCurve",
        "CICMYKHalftone",
    ]
    
    var player: AVPlayer?
    var playerItem: AVPlayerItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = videoUrl else { return }

        originalImage = VideoUtils().videoPreviewImage(url: url)
        
        self.filterCollectionView.dataSource = self
        self.filterCollectionView.delegate = self
        self.filterCollectionView.register(FilterViewCell.self, forCellWithReuseIdentifier: "FilterCell")

        configurePlayer(url)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        playPauseButton.updateUI()
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: UIButton) {
        
        let isPlaying = player?.rate != 0 && player?.error == nil
        if isPlaying {
            player?.pause()
        }
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.gradient)

        guard let url = videoUrl else { return }
        
        let filename = VideoUtils().uniqueFileNameWithExtention(fileExtension: "mov")
        //VideoUtils().writeToFile(url: url, filename: filename)
        saveFilteredVideo(url: url)
        VideoUtils().uploadMetadata(localFile: url, serverFileName: filename, filter: selectedFilter) { (isSuccess, documentID) in
            
            SVProgressHUD.dismiss()
            if isSuccess {
                DataManager.shared.firstVC.getAllVideos()
                DataManager.shared.firstVC.collectionView.reloadData()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    func configurePlayer(_ url: URL){
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            let inputImage = request.sourceImage
            var output = inputImage
            
            if let filter = self.selectedFilter {
                output = inputImage.applyingFilter(filter)
            }
            request.finish(with: output, context: nil)
        })

        player = AVPlayer(playerItem: playerItem)
        player?.rate = 1
        player?.isMuted = false

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

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
            self.player?.seek(to: CMTime.zero)
        }
    }
    
    
    
    private func saveFilteredVideo(url: URL){
        
        
        do {
                let asset = AVAsset(url: url)

                //self.player.replaceCurrentItem(with: playerItem)
                if let player = playerItem  {
                    print("start: ", player)

                    let exporter = AVAssetExportSession(asset: player.asset, presetName: AVAssetExportPresetHighestQuality)
                    
                    exporter?.videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                        let inputImage = request.sourceImage
                        var output = inputImage
                        
                        if let filter = self.selectedFilter {
                            output = inputImage.applyingFilter(filter)
                        }
                        request.finish(with: output, context: nil)
                    })
                    
                    exporter?.outputFileType = .mov
                    let filename = VideoUtils().uniqueFileNameWithExtention(fileExtension: "mov")
                    VideoUtils().writeToFile(url: url, filename: filename)
                    let videoData = try Data(contentsOf: url)
                    let fm = FileManager.default

                      guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                          print("Unable to reach the documents folder")
                          return
                      }
                       let outputURL = docUrl.appendingPathComponent(filename)
                    
                    //try videoData.write(to: outputURL)
                    exporter?.outputURL = outputURL
                    exporter?.exportAsynchronously(completionHandler: {
                        guard exporter?.status == .completed else {
                            print("export failed: \(String(describing: exporter?.error))")
                            return
                        }
                        print("done1: ",docUrl, outputURL)
                    }
                )
                }
            
        } catch {
           print("could not save data")
        }

    }
}


extension PreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CIFilterNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = filterCollectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterViewCell
        
        if let thumbnail = originalImage {
            cell.setData(filter: CIFilterNames[indexPath.row], originalImage: thumbnail)
        }
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        selectedFilter = CIFilterNames[indexPath.row]
        
        let isPlaying = player?.rate != 0 && player?.error == nil
        if(!isPlaying){
           player?.currentItem?.videoComposition = player?.currentItem?.videoComposition?.mutableCopy() as? AVVideoComposition
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 75, height: 95)
    }
    
}

