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
    @IBOutlet weak var filtersScrollView: UIScrollView!
    @IBOutlet weak var actionBar: UIView!

    var videoUrl:  URL?
    var isEdit = true
    var playPauseButton: PlayPauseButton!
    var originalImage: UIImage?
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isEdit {
            filtersScrollView.isHidden = true
            actionBar.isHidden = true
        }

        guard let url = videoUrl else { return }
        originalImage = videoPreviewImage(url: url)
        createFilterCard()
        configurePlayer(url)
        
        print("url==>\(url)")

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
        
                
        let filename = uniqueFileNameWithExtention(fileExtension: "mov")
        writeToFile(url: url, filename: filename)
        FirebaseStorageManager().uploadMetadata(localFile: url, serverFileName: filename, filter: selectedFilter) { (isSuccess, documentID) in
            
            SVProgressHUD.dismiss()
            if isSuccess {
                self.dismiss(animated: true, completion: nil)
            }
        
            print("uploadImageData: \(isSuccess), \(String(describing: documentID))")
        }
    }
    
    @objc func filterButtonTapped(sender: UIButton) {
        selectedFilter = CIFilterNames[sender.tag]
        
        let isPlaying = player?.rate != 0 && player?.error == nil
        if(!isPlaying){
           player?.currentItem?.videoComposition = player?.currentItem?.videoComposition?.mutableCopy() as? AVVideoComposition
        }
    }
    
    
    func createFilterCard() {
        var xCoord: CGFloat = 8
        let yCoord: CGFloat = 8
        let buttonWidth:CGFloat = 75
        let buttonHeight: CGFloat = 95
        let gapBetweenButtons: CGFloat = 8
        
        var itemCount = 0
             
        for i in 0..<CIFilterNames.count {
            itemCount = i
                 
            let filterButton = UIButton(type: .custom)
            filterButton.frame = CGRect(x: xCoord, y: yCoord, width: buttonWidth, height: buttonHeight)
            filterButton.tag = itemCount
            filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
            filterButton.layer.cornerRadius = 6
            filterButton.clipsToBounds = true
             
            let context = CIContext()
            let filterImage = CIImage(image: originalImage!)
            let output = filterImage!.applyingFilter("\(CIFilterNames[i])")
            
            guard let cgImage = context.createCGImage(output, from: output.extent) else {
                return
            }
            guard let orientation = originalImage?.imageOrientation else {
                return
            }
            
            let imageForButton = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
            filterButton.setBackgroundImage(imageForButton, for: .normal)
            
            xCoord +=  buttonWidth + gapBetweenButtons
                  filtersScrollView.addSubview(filterButton)
            filtersScrollView.contentSize = CGSize(width: buttonWidth * CGFloat(itemCount+2), height: yCoord)

        }
    }
    
    func configurePlayer(_ url: URL){
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
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
            self.player?.currentItem?.videoComposition = self.player?.currentItem?.videoComposition
        }
    }
    
    func videoPreviewImage(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: CMTime(seconds: 2, preferredTimescale: 60), actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        else {
            return nil
        }
    }
    
    func uniqueFileNameWithExtention(fileExtension: String) -> String {
        let uniqueString: String = ProcessInfo.processInfo.globallyUniqueString
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddh hmmsss"
        let dateString: String = formatter.string(from: Date())
        let uniqueName: String = "\(uniqueString)_\(dateString)"
        if fileExtension.count > 0 {
            let fileName: String = "\(uniqueName).\(fileExtension)"
            return fileName
        }
        return uniqueName
    }
    
    func writeToFile(url: URL, filename: String) {
        do {
           let videoData = try Data(contentsOf: url)
           let fm = FileManager.default

           guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
               print("Unable to reach the documents folder")
               return
           }
            let localUrl = docUrl.appendingPathComponent(filename)
            try videoData.write(to: localUrl)
            print("<==localUrl: \(localUrl)==>")
        } catch {
           print("could not save data")
        }
    }

}
