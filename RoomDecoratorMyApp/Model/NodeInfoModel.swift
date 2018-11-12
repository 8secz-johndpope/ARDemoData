//
//  NodeInfoModel.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 15/10/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import Foundation
import UIKit

struct NodeInfoModel :  Codable
{
    var nodeWidth:CGFloat?
    var nodeHeight:CGFloat?
    var nodeImage:String?
    var nodeFrameImage:String?
    
    
    init() {
    }
    
    init(width:CGFloat,height : CGFloat, nodeImg:String,nodeFrme:String) {
        nodeWidth =  width
        nodeHeight =  height
        nodeImage = nodeImg
        nodeFrameImage = nodeFrme
    }
    
    
    enum CodableKey: String, CodingKey {
        case nodeImge
        case nodeFrameImge
        case width
        case height
    }
    
//    func encode(to encoder: Encoder) throws {
//        
//        var container = encoder.container(keyedBy: CodableKey.self)
// 
//        let nodeImageData = try NSKeyedArchiver.archivedData(withRootObject: nodeImage!, requiringSecureCoding: false)
//        try container.encode(nodeImageData, forKey: .nodeImge)
//        
//        let nodeFrameData = try NSKeyedArchiver.archivedData(withRootObject: nodeFrameImage!, requiringSecureCoding: false)
//        try container.encode(nodeFrameData, forKey: .nodeFrameImge)
//        
//        try container.encode(nodeWidth, forKey: .width)
//        try container.encode(nodeHeight, forKey: .height)
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodableKey.self)
//        
//        let imgData = try container.decode(Data.self, forKey: .nodeImge)
//        nodeImage = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imgData)
//        
//        let imgData1 = try container.decode(Data.self, forKey: .nodeFrameImge)
//        nodeFrameImage = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imgData1)
//        
//        nodeWidth = try container.decode(CGFloat.self, forKey: .width)
//        nodeHeight = try container.decode(CGFloat.self, forKey: .height)
//
//    }
}



