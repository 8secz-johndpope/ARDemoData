//
//  ImageSizeModel.swift
//  ARKitImageDetectionTutorial
//
//  Created by admin on 06/09/18.
//  Copyright © 2018 Ivan Nesterenko. All rights reserved.
//

import Foundation
import UIKit
struct ImageSizeModel {
    
    var image:String? = nil
    var availablesWidthSize:[Int] = []
    var availablesHeightSize:[Int] = []

    init() {
        
    }
    
    init(image:String , width:[Int], height : [Int]) {
        
        self.image = image
        self.availablesWidthSize = width
        self.availablesHeightSize = height
     }
    
    func formatedSize(width:Int, height:Int) -> String {
        return width.description+" "+height.description+" inches"
    }
    
    func getData() -> [ImageSizeModel]   {
    var data:[ImageSizeModel] = [ImageSizeModel]()
      data.append(ImageSizeModel.init(image: "Image01.png", width: [16,24,30,36], height: [16,24,30,36]))
     return data
  }
  
    func getFrameData() -> [ImageSizeModel]   {
        var data:[ImageSizeModel] = [ImageSizeModel]()
        data.append(ImageSizeModel.init(image: "Frame-01.png", width: [16,24,30,36], height: [16,24,30,36]))
        data.append(ImageSizeModel.init(image: "Frame-02.png", width: [16,24,30,36], height: [16,24,30,36]))
        data.append(ImageSizeModel.init(image: "Frame-03.png", width: [16,24,30,36], height: [16,24,30,36]))
        return data
    }
    
}

class Singleton{
    public static let shared = Singleton()
    private init() {}
    
    func createFrameFromImage(image:UIImage , size :CGSize) -> UIImage
    {
        //let resizedimage = image.resizableImage(withCapInsets: UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0), resizingMode: UIImageResizingMode.stretch)
        //let rect = TSRect.init(x: 0, y: 0, width: size.width, height: size.height, unit: TSUnit.inch).cgrect
        let imageSize = CGSize.init(width: size.width , height: size.height)
        //let imageSize = rect.size
        UIGraphicsBeginImageContext(imageSize)
        let width = imageSize.width
        let height = imageSize.height
        var letTop = image
        let rightTop = rotateImageByAngles(image: &letTop, angles: .pi/2) // correct
        let rightBottom = rotateImageByAngles(image: &letTop, angles: -.pi) // correct
        let leftBottom = rotateImageByAngles(image: &letTop, angles: -.pi/2) // correct
        letTop.draw(in: CGRect(x: 0, y: 0, width: width/2, height: height/2))
        rightTop.draw(in: CGRect(x: (width/2) , y: 0, width: width/2, height: height/2))
        leftBottom.draw(in: CGRect(x: 0, y: height/2, width: width/2 + 5, height: height/2))
        rightBottom.draw(in: CGRect(x: (width/2) , y: (height/2), width: width/2, height: height/2))
        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else { return rightTop }
        UIGraphicsEndImageContext()
        return finalImage
    }
    
    func rotateImageByAngles(image:inout UIImage , angles : CGFloat) -> UIImage{
        let rotatedSize = CGRect.init(origin: .zero, size: CGSize(width: image.size.width, height: image.size.height))
         .applying(CGAffineTransform.init(rotationAngle: angles))
         .integral.size
        UIGraphicsBeginImageContext(rotatedSize)

       if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
        context.translateBy(x: origin.x, y: origin.y)
        context.rotate(by: angles)
        image.draw(in: CGRect(x: -origin.x, y: -origin.y,
                              width: image.size.width, height: image.size.height))
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage ?? image
        }
        return image
    }
    
    
    func createRectangularHorizontalImage(image:UIImage , size :CGSize) -> UIImage {
        // rotate image by 90 degress and join with actual to make a rectangular block
        // create asqaure box 
        return UIImage()
    }
}

extension UIImage {
    
    
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        
        let size = self.size
        let aspectRatio =  size.width/size.height
        
        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {                            // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else {                                        // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }
            
        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }
        
        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        return newImage
    }
}


