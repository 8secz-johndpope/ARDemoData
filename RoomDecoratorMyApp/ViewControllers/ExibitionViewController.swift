//
//  ExibitionViewController.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 27/12/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import UIKit
import ARKit

class ExibitionViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        return configuration
    }()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.sceneView.debugOptions = [.showFeaturePoints]
        self.sceneView.delegate = self
        self.sceneView.session.run(standardConfiguration)
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(sender : UITapGestureRecognizer)  {
        
        guard let scene = sender.view as? ARSCNView else { return }
        let touchLocation = sender.location(in: scene)
        let hitResults = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.estimatedHorizontalPlane)
        if !hitResults.isEmpty{
        // add portal here
             //addExibitionRoom(hitResult: hitResults.first!)
             addPictures(hitResult: hitResults.first!)
        }
    }
    
    
    func addExibitionRoom(hitResult : ARHitTestResult) {
        
        let scn = SCNScene(named: "art.scnassets/Gallery.scn")
        guard let portalNode = scn?.rootNode.childNode(withName: "portal", recursively: false) else {
            print("portal node not found")
            return}
        let tranform = hitResult.worldTransform
        let planeXPosition = tranform.columns.3.x
        let planeYPosition = tranform.columns.3.y
        let planeZPosition = tranform.columns.3.z
        portalNode.position = SCNVector3(planeXPosition,planeYPosition,planeZPosition)
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        addWall(nodeName: "doorwallleft", parent: portalNode, image: "sideDoorA")
        addWall(nodeName: "doorwallright", parent: portalNode, image: "sideDoorB")
        addWall(nodeName: "sidewallleft", parent: portalNode, image: "sideA")
        addWall(nodeName: "sidewallright", parent: portalNode, image: "sideB")
        addWall(nodeName: "backwall", parent: portalNode, image: "back")
        addPlaneContent(nodeName: "top", parent: portalNode, image: "top")
        addPlaneContent(nodeName: "floor", parent: portalNode, image: "bottom")
        addImagesToExibition(node: portalNode)
     }
    
    func addWall(nodeName:String, parent:SCNNode , image:String){
        //recursively is true because wall node are direct child of portal
        let childNode = parent.childNode(withName: nodeName, recursively: true)
        childNode?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/\(image)")
        childNode?.renderingOrder = 200
        if let mask = childNode?.childNode(withName: "mask", recursively: false){
            mask.geometry?.firstMaterial?.transparency = 0.0001
        }
    }
    
    func addPlaneContent(nodeName:String, parent:SCNNode , image:String){
        //recursively is true because wall node are direct child of portal
        let childNode = parent.childNode(withName: nodeName, recursively: true)
        childNode?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/\(image)")
        childNode?.renderingOrder = 200
    }
    
    func addImagesToExibition(node : SCNNode){
        //getting floor node
        let childNode = node.childNode(withName: "sidewallleft", recursively: true)
        let photoRingNode = SCNNode(geometry: SCNPlane(width: 1.0, height: 1.0))
        photoRingNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "image002.png")
        photoRingNode.position = SCNVector3Make(0.02, 0, 0)
        photoRingNode.eulerAngles.y = (.pi/2)
        photoRingNode.renderingOrder = 200
        childNode?.addChildNode(photoRingNode)
        
 //        let photoW: CGFloat       = 1.8
//        let photoH: CGFloat       = photoW * 0.618
//         let imageArray = [UIImage(named: "image001.png"),UIImage(named: "image002.png"),UIImage(named: "image003.png"),UIImage(named: "image004.png"),UIImage(named: "image005.png"),UIImage(named: "image006.png"),UIImage(named: "image007.png")]
//        let boxW: CGFloat       = 0.36
//        var materials: [SCNMaterial] = []
//
//        for  image in imageArray {
//            let box = SCNBox(width: boxW, height: boxW, length: boxW, chamferRadius: 0)
//            let material = SCNMaterial()
//            material.multiply.contents = image
//            materials.append(material)
//            box.materials = materials
//            let boxNode = SCNNode(geometry: box)
//            photoRingNode.addChildNode(boxNode)
//        }
    }
    
    func addPictures(hitResult : ARHitTestResult) {
        
        let wallNode = SCNNode(geometry: SCNPlane(width: 3.0, height: 0.03))
        wallNode.geometry?.firstMaterial?.diffuse.contents =  UIColor.red
        let tranform = hitResult.worldTransform
        let planeXPosition = 0.0
        let planeYPosition = tranform.columns.3.y
        let planeZPosition = 0.0
        wallNode.position = SCNVector3(planeXPosition,Double(planeYPosition),planeZPosition)
        wallNode.eulerAngles.x = (.pi/2)
        wallNode.eulerAngles.y = -0
        self.sceneView.scene.rootNode.addChildNode(wallNode)
        
        let picXPosition = -1.0
        let picYPosition = -1.5
        let picZPosition = -1.5
        
        let imageArray = [UIImage(named: "image001.png"),UIImage(named: "image002.png"),UIImage(named: "image003.png"),UIImage(named: "image004.png"),UIImage(named: "image005.png"),UIImage(named: "image006.png"),UIImage(named: "image007.png")]
        
        for  (index,image) in imageArray.enumerated(){
            let photoRingNode = SCNNode()
 
           // photoRingNode.position = SCNVector3Make((Float((picXPosition) + 0.1)), Float(picYPosition), (Float(index) * Float(picZPosition) + 0.1))
            photoRingNode.position = SCNVector3(picXPosition,(picYPosition * Double(index)) + 0.5,picZPosition)
            photoRingNode.eulerAngles.y = (.pi/2)
            wallNode.insertChildNode(photoRingNode, at: index)
            
            let photoNode = SCNNode(geometry:SCNPlane(width: 1.0, height: 1.0))
            photoNode.geometry?.firstMaterial?.diffuse.contents = image
            photoNode.position = SCNVector3Make(0, 0, 0.05)
            photoNode.eulerAngles.z = -(.pi/2)
            photoRingNode.addChildNode(photoNode)
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
extension ExibitionViewController : ARSCNViewDelegate{
    
}
