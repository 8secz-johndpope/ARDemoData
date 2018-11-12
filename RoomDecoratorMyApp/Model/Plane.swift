//
//  Plane.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 25/09/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import Foundation
import ARKit
class Plane: SCNNode {
    var planeAnchor: ARImageAnchor
    
    var planeGeometry: SCNPlane
    var planeNode: SCNNode
    
    init(_ anchor: ARImageAnchor, image : String) {
        
        //print(image ?? "name not found")
        
        self.planeAnchor = anchor
        
        //let grid = UIImage(named: image)
        self.planeGeometry = SCNPlane(width: CGFloat(0.34), height: CGFloat(0.25))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black.withAlphaComponent(0.6)
        self.planeGeometry.materials = [material]
        self.planeNode = SCNNode(geometry: planeGeometry)
        self.planeNode.eulerAngles.x = -.pi / 2

        super.init()
        self.addChildNode(planeNode)
        
     }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
