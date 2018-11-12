//
//  ImageInfoNode.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 25/09/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import Foundation
import UIKit
class ImageInfoData {
    
    struct ImageInfo {
    var image:UIImage
    var inforStrng:String
        var imageName:String
   }
    
    func createImageInfoArray() ->  [ImageInfo] {
        var imageInfoData  = [ImageInfo]()
        imageInfoData.append(ImageInfo(image: UIImage(named: "image001.png")!, inforStrng: "Evenings in the valleys of Ladakh bring with it avenues shrouded in a mystical beauty. The sky in its varying shades of blue still glows with some light from the evening sun, but the mountains seem to be slipping in a slumber. They hide within them a blue-purple magic which makes for an enchanting scene. The snow still glints in a glory of its own, shining beautifully off the blue mountains. This photograph in expanded dimensions, framed in a suitable colour, does not fail to mesmerize. The purifying vibes its exudes make it a great choice for adding to your home décor, as well as for gifting.",imageName: "image001"))
        
        imageInfoData.append(ImageInfo(image: UIImage(named: "image002.png")!, inforStrng: "Painted by the Hand of God, the scene captured by LC Singh, is a delight to look at. The terrains of Ladakh offer limitless visual expressions, like the one in this picture. The hills vary beautifully in shade and texture and the gray clouds add to the magic of the place. Reflecting over this wholesome dose of nature’s beauty can be a serene experience and can awaken the tiny Buddha in you. When did you last see a place so beautiful that it compelled you to jaunt about, explore it, and simply revel in its wonder? Add more joy to your day by making this nature photograph a part of your home or office.", imageName: "image002"))
        imageInfoData.append(ImageInfo(image: UIImage(named: "image003.png")!, inforStrng: "Have you ever seen something so calming that it inexplicably stirs you from within? The Pangong lake in Ladakh makes for one such sight. The lake is so clear that it beautifully reflects the cerulean blue of the skies above. The snow-capped hills with their earthy hues perfectly complement the waters. This is a picture which glorifies three important elements of nature – Earth, Water & Sky. Even the air can be sensed in the ripples created over the lake. Painted by the Hand of God, this scene would be an apt addition to your meditation room. The purifying vibes it exudes makes it a great choice for adding to your home décor, as well as for gifting.", imageName: "image003"))
        return imageInfoData
    }
}

