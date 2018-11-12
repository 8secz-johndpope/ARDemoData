//
//  GalleryInfoViewController.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 25/09/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import UIKit
import ARKit

class GalleryInfoViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    /// Variable Declaration(s)
    var planes = [ARImageAnchor: Plane]()
    var nodeArray :[SCNNode] = [SCNNode]()
    let data = ImageInfoData().createImageInfoArray()
    var currentNode:SCNNode?
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
            ])
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpTrackingImages()
    }
   
    
    func setUpTrackingImages() {
        
        var set: Set<ARReferenceImage> = Set<ARReferenceImage>()
        for object in data{
            let referenceImage = ARReferenceImage.init((object.image.cgImage)!, orientation: CGImagePropertyOrientation.up, physicalWidth: 1.9812)
            referenceImage.name = object.imageName
            set.insert(referenceImage)
        }
        
        // Create a new scene
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.debugOptions = [SCNDebugOptions.showWorldOrigin]
        sceneView.delegate = self
        
        
        if #available(iOS 12.0, *) {
            let configuration = ARImageTrackingConfiguration()
            configuration.trackingImages = set
            sceneView.session.run(configuration, options: [ARSession.RunOptions.removeExistingAnchors, ARSession.RunOptions.resetTracking])  }
        else {
            // Fallback on earlier versions
            let configuration = ARWorldTrackingConfiguration()
            configuration.detectionImages = set
            sceneView.session.run(configuration, options: [ARSession.RunOptions.removeExistingAnchors, ARSession.RunOptions.resetTracking])  }
        }
     
    
    func degreesToRadians (_ value:Double) -> CGFloat {
        return (CGFloat)(value * Double.pi / 180.0)
    }
    
    func createTextNode(attributedString: NSMutableAttributedString) -> SCNNode {
        let extrudedText = SCNText(string: attributedString, extrusionDepth: 0.1)
        extrudedText.font = UIFont(name: "Helvetica", size: 0.2)!
        extrudedText.containerFrame = CGRect(origin: .zero, size: CGSize(width: 200.0, height: 100.0))
        extrudedText.truncationMode = CATextLayerTruncationMode.none.rawValue
        extrudedText.isWrapped = false
        extrudedText.alignmentMode = CATextLayerAlignmentMode.justified.rawValue
        extrudedText.firstMaterial?.diffuse.contents = UIColor.blue
        let textNode = SCNNode()
        textNode.geometry = extrudedText
        
        // Update pivot of object to its center
        let (min, max) = textNode.boundingBox
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        textNode.scale = SCNVector3Make(0.01, 0.01, 0.01)
        textNode.eulerAngles.x = -.pi / 2
        return textNode
    }
    
    func displayTextNode(imageAnchor : ARImageAnchor, str : NSMutableAttributedString, name :String) {
        
        let textLabel = UITextView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: CGFloat(imageAnchor.referenceImage.physicalSize.width * 2834.65), height: CGFloat(imageAnchor.referenceImage.physicalSize.height * 2834.65))))
        textLabel.attributedText = str
        textLabel.textContainerInset = UIEdgeInsets(top: 40, left: 20, bottom: 20, right: 40)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.font = UIFont(name: "Helvetica", size: 35)
        textLabel.textAlignment = NSTextAlignment.justified
        let image = UIImage.imageWithLabel(textLabel)
        textLabel.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        textLabel.frame.size.height = textLabel.contentSize.height
        
        
        let plane = SCNPlane(width: CGFloat(imageAnchor.referenceImage.physicalSize.width), height: CGFloat(imageAnchor.referenceImage.physicalSize.height))
        plane.cornerRadius = 0.01
        let planeNode = SCNNode(geometry: plane)
        planeNode.geometry?.firstMaterial?.diffuse.contents = image
        planeNode.geometry?.firstMaterial?.blendMode = SCNBlendMode.alpha
        planeNode.position = SCNVector3(x: imageAnchor.transform.columns.3.x, y:imageAnchor.transform.columns.3.y - 0.2, z: -1.5)
        planeNode.name = name
        self.sceneView.scene.rootNode.addChildNode(planeNode)
        self.currentNode = planeNode
        
        // 5. Animate appearance by scaling model from 0 to previously calculated value.
        let appearanceAction = SCNAction.scale(to: CGFloat(2.0), duration: 0.4)
        appearanceAction.timingMode = .easeOut
        planeNode.scale = SCNVector3Make(0.001, 0.001, 0.001)
        planeNode.runAction(appearanceAction)
        
    }
    
    func getTextNode(imageAnchor : ARImageAnchor, str : NSMutableAttributedString, name :String) -> UIImage {
        
        let textLabel = UITextView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 720.0, height: 1280.0)))
        textLabel.attributedText = str
        textLabel.textContainerInset = UIEdgeInsets(top: 40, left: 20, bottom: 20, right: 40)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.font = UIFont(name: "Helvetica", size: 40)
        textLabel.textAlignment = NSTextAlignment.justified
        let image = UIImage.imageWithLabel(textLabel)
        textLabel.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        textLabel.frame.size.height = textLabel.contentSize.height
        return image
    }
}
//MARK: - ARSCNViewDelegate
extension GalleryInfoViewController : ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else {return}
        
        let imageSize = imageAnchor.referenceImage.physicalSize
        let string = self.data.first(where: {$0.imageName == imageAnchor.referenceImage.name})?.inforStrng ?? "Data not found"
        print(string)
        let plane = SCNPlane(width: CGFloat(imageSize.width), height: CGFloat(imageSize.height))
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        
        let imageHightingAnimationNode = SCNNode(geometry: plane)
        imageHightingAnimationNode.eulerAngles.x = -.pi / 2
        imageHightingAnimationNode.opacity = 0.25
        node.addChildNode(imageHightingAnimationNode)
        
        imageHightingAnimationNode.runAction(imageHighlightAction){
            
            DispatchQueue.main.async {
                
                
                let attributedString = NSMutableAttributedString(string: string)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 5
                attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
                
                if imageAnchor.referenceImage.name != self.currentNode?.name || self.currentNode == nil{
                    self.currentNode?.removeFromParentNode()
                    print("physical size = \(imageAnchor.referenceImage.physicalSize)")
                    
                    let plane = SCNPlane(width: CGFloat(imageSize.width/2), height: CGFloat(imageSize.height + 0.0254))
                    plane.cornerRadius = 0.01
                    let planeNode = SCNNode(geometry: plane)
                    planeNode.geometry?.firstMaterial?.diffuse.contents = self.getTextNode(imageAnchor: imageAnchor, str: attributedString, name: imageAnchor.referenceImage.name!)
                    planeNode.eulerAngles.x = -.pi / 2
                    node.addChildNode(planeNode)
                    planeNode.position.x = 0.0
                    self.currentNode = planeNode
                    let moveAction = SCNAction.move(by: SCNVector3(0.75, 0, 0), duration: 0.6)
                    planeNode.runAction(moveAction)
                }
            }
        }
    }
}

extension GalleryInfoViewController : ARSessionDelegate{
    
}
