//
//  CollectionViewCell.swift
//  Camshot
//
//  Created by Timi Tejumola on 09/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import UIKit

class FilterViewCell: UICollectionViewCell {
    let bg : UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 6
        iv.clipsToBounds = true
        return iv
     }()
    
    override var isSelected: Bool {
      didSet {
        self.contentView.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0.4768902063, alpha: 1)
        self.contentView.layer.borderWidth = isSelected ? 4.0 : 0.0
        self.contentView.layer.cornerRadius = isSelected ? 6.0 : 0.0

      }
    }
    
    
      override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(bg)
        bg.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        bg.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        bg.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        bg.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true


      }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViews(){
    }
    
    
    func setData(filter: String, originalImage: UIImage) {
        let context = CIContext()
        let filterImage = CIImage(image: originalImage)
        let output = filterImage!.applyingFilter(filter)

        guard let cgImage = context.createCGImage(output, from: output.extent) else {
          return
        }
        let orientation = originalImage.imageOrientation

        bg.image = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}
