//
//  VirtualNode.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 18/09/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import Foundation
import ARKit

class VirtualNode : SCNNode{
   
    var anchor : ARAnchor!
    
    init(geometry : SCNGeometry) {
        super.init()
        self.geometry = geometry
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        self.eulerAngles.x = -.pi/2
      }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
        
    } 
    
    func react() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.completionBlock = {
            SCNTransaction.animationDuration = 0.15
            self.opacity = 1.0
        }
        self.opacity = 0.5
        SCNTransaction.commit()
    }
   
}
