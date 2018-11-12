//
//  FocalNode.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 18/09/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import Foundation
import SceneKit

class FocalNode: SCNNode {
    
    let size: CGFloat = 0.1
    let segmentWidth: CGFloat = 0.004
    
    // MARK: - Configuration Properties
    
    // Original size of the focus square in meters.
    static let size: Float = 0.17
    
    // Thickness of the focus square lines in meters.
    static let thickness: Float = 0.018
    
    // Scale factor for the focus square when it is closed, w.r.t. the original size.
    static let scaleForClosedSquare: Float = 0.97
    
    // Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
    static let sideLengthForOpenSegments: CGFloat = 0.2
    
    // Duration of the open/close animation
    static let animationDuration = 0.7
    
    static let primaryColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
    
    // Color of the focus square fill.
    static let fillColor = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1)
    
    /// List of the segments in the focus square.
    private var segments: [FocalNode.Segment] = []
    
    /// The primary node that controls the position of other `FocusSquare` nodes.
    private let positioningNode = SCNNode()
    
    private lazy var fillPlane: SCNNode = {
        let correctionFactor = FocusSquare.thickness / 2 // correction to align lines perfectly
        let length = CGFloat(1.0 - FocusSquare.thickness * 2 + correctionFactor)
        
        let plane = SCNPlane(width: length, height: length)
        let node = SCNNode(geometry: plane)
        node.name = "fillPlane"
        node.opacity = 0.0
        
        let material = plane.firstMaterial!
        material.diffuse.contents = FocusSquare.fillColor
        material.isDoubleSided = true
        material.ambient.contents = UIColor.black
        material.lightingModel = .constant
        material.emission.contents = FocusSquare.fillColor
        
        return node
    }()

    
    private let colorMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        return material
    }()
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func createSegment(width: CGFloat, height: CGFloat) -> SCNNode {
        let segment = SCNPlane(width: width, height: height)
        segment.materials = [colorMaterial]
        
        return SCNNode(geometry: segment)
    }
    
    private func addHorizontalSegment(dx: Float) {
        let segmentNode = createSegment(width: segmentWidth, height: size)
        segmentNode.position.x += dx
        
        addChildNode(segmentNode)
    }
    
    private func addVerticalSegment(dy: Float) {
        let segmentNode = createSegment(width: size, height: segmentWidth)
        segmentNode.position.y += dy
        
        addChildNode(segmentNode)
    }
    
    private func setup() {
//        let dist = Float(size) / 2.0
//        addHorizontalSegment(dx: dist)
//        addHorizontalSegment(dx: -dist)
//        addVerticalSegment(dy: dist)
//        addVerticalSegment(dy: -dist)
        
        // Rotate the node so the square is flat against the floor
        //transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        opacity = 0.0
        
        /*
         The focus square consists of eight segments as follows, which can be individually animated.
         
            s1  s2
             _   _
         s3 |     | s4
         
         s5 |     | s6
             -   -
            s7  s8
         */
        let s1 = Segment(name: "s1", corner: .topLeft, alignment: .horizontal)
        let s2 = Segment(name: "s2", corner: .topRight, alignment: .horizontal)
        let s3 = Segment(name: "s3", corner: .topLeft, alignment: .vertical)
        let s4 = Segment(name: "s4", corner: .topRight, alignment: .vertical)
        let s5 = Segment(name: "s5", corner: .bottomLeft, alignment: .vertical)
        let s6 = Segment(name: "s6", corner: .bottomRight, alignment: .vertical)
        let s7 = Segment(name: "s7", corner: .bottomLeft, alignment: .horizontal)
        let s8 = Segment(name: "s8", corner: .bottomRight, alignment: .horizontal)
        segments = [s1, s2, s3, s4, s5, s6, s7, s8]
        
        let sl: Float = 0.5  // segment length
        let c: Float = FocusSquare.thickness / 2 // correction to align lines perfectly
        s1.simdPosition += float3(-(sl / 2 - c), -(sl - c), 0)
        s2.simdPosition += float3(sl / 2 - c, -(sl - c), 0)
        s3.simdPosition += float3(-sl, -sl / 2, 0)
        s4.simdPosition += float3(sl, -sl / 2, 0)
        s5.simdPosition += float3(-sl, sl / 2, 0)
        s6.simdPosition += float3(sl, sl / 2, 0)
        s7.simdPosition += float3(-(sl / 2 - c), sl - c, 0)
        s8.simdPosition += float3(sl / 2 - c, sl - c, 0)
        
        positioningNode.eulerAngles.x = .pi / 2 // Horizontal
        positioningNode.simdScale = float3(FocalNode.size * FocalNode.scaleForClosedSquare)
        for segment in segments {
            positioningNode.addChildNode(segment)
        }
        positioningNode.addChildNode(fillPlane)
        addChildNode(positioningNode)
        
       // simdTransform = matrix_identity_float4x4
       // eulerAngles.x = .pi / 2
       // simdPosition = float3(0, 0, -0.8)
     }
     
}
extension FocalNode {
    
    /*
     The focus square consists of eight segments as follows, which can be individually animated.
     
         s1  s2
         _   _
     s3 |     | s4
     
     s5 |     | s6
         -   -
       s7  s8
     */
    enum Corner {
        case topLeft // s1, s3
        case topRight // s2, s4
        case bottomRight // s6, s8
        case bottomLeft // s5, s7
    }
    
    enum Alignment {
        case horizontal // s1, s2, s7, s8
        case vertical // s3, s4, s5, s6
    }
    
    enum Direction {
        case up, down, left, right
        
        var reversed: Direction {
            switch self {
            case .up:   return .down
            case .down: return .up
            case .left:  return .right
            case .right: return .left
            }
        }
    }
    
    class Segment: SCNNode {
        
        // MARK: - Configuration & Initialization
        
        /// Thickness of the focus square lines in m.
        static let thickness: CGFloat = 0.018
        
        /// Length of the focus square lines in m.
        static let length: CGFloat = 0.5  // segment length
        
        /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
        static let openLength: CGFloat = 0.2
        
        let corner: Corner
        let alignment: Alignment
        let plane: SCNPlane
        
        init(name: String, corner: Corner, alignment: Alignment) {
            self.corner = corner
            self.alignment = alignment
            
            switch alignment {
            case .vertical:
                plane = SCNPlane(width: Segment.thickness, height: Segment.length)
            case .horizontal:
                plane = SCNPlane(width: Segment.length, height: Segment.thickness)
            }
            super.init()
            self.name = name
            
            let material = plane.firstMaterial!
            material.diffuse.contents = FocusSquare.primaryColor
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = FocusSquare.primaryColor
            geometry = plane
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("\(#function) has not been implemented")
        }
        
        // MARK: - Animating Open/Closed
        
        var openDirection: Direction {
            switch (corner, alignment) {
            case (.topLeft,     .horizontal):   return .left
            case (.topLeft,     .vertical):     return .up
            case (.topRight,    .horizontal):   return .right
            case (.topRight,    .vertical):     return .up
            case (.bottomLeft,  .horizontal):   return .left
            case (.bottomLeft,  .vertical):     return .down
            case (.bottomRight, .horizontal):   return .right
            case (.bottomRight, .vertical):     return .down
            }
        }
        
        func open() {
            if alignment == .horizontal {
                plane.width = Segment.openLength
            } else {
                plane.height = Segment.openLength
            }
            
            let offset = Segment.length / 2 - Segment.openLength / 2
            updatePosition(withOffset: Float(offset), for: openDirection)
        }
        
        func close() {
            let oldLength: CGFloat
            if alignment == .horizontal {
                oldLength = plane.width
                plane.width = Segment.length
            } else {
                oldLength = plane.height
                plane.height = Segment.length
            }
            
            let offset = Segment.length / 2 - oldLength / 2
            updatePosition(withOffset: Float(offset), for: openDirection.reversed)
        }
        
        private func updatePosition(withOffset offset: Float, for direction: Direction) {
            switch direction {
            case .left:     position.x -= offset
            case .right:    position.x += offset
            case .up:       position.y -= offset
            case .down:     position.y += offset
            }
        }
        
    }
}
