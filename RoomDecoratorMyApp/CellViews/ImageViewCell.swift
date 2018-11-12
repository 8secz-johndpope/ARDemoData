//
//  ImageViewCell.swift
//  ARKitImageDetectionTutorial
//
//  Created by admin on 30/08/18.
//  Copyright © 2018 Ivan Nesterenko. All rights reserved.
//

import UIKit

class ImageViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
     
    
    func setImage(image:UIImage)
        {
            self.imageView.image = image
        }
    
}
