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
        imageView.layer.cornerRadius = 5
    }
    
    func setData(video: Video){
        let originalImage = VideoUtils().videoPreviewImage(url: video.url)

        
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
        imageView.backgroundColor = UIColor(patternImage: videoThubnail)
    }

}
