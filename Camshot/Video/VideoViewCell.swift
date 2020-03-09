//
//  VideoViewCell.swift
//  Camshot
//
//  Created by Timi Tejumola on 09/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import UIKit
import AVFoundation

class VideoViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageView.layer.cornerRadius = 5
    }
    
    func setData(video: Video){
        let originalImage = videoPreviewImage(url: video.url)
        
        let context = CIContext()
        let filterImage = CIImage(image: originalImage!)
        let output = filterImage!.applyingFilter(video.filter!)
        
        guard let cgImage = context.createCGImage(output, from: output.extent) else {
            return
        }
        
        guard let orientation = originalImage?.imageOrientation else {
            return
        }
        
        let videoThubnail = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        print(videoThubnail)

        imageView.backgroundColor = UIColor(patternImage: videoThubnail)
    }
    
    private func videoPreviewImage(url: URL) -> UIImage? {
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

}
