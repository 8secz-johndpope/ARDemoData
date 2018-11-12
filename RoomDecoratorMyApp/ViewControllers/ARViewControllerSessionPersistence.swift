//
//  ARViewControllerSessionPersistence.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 15/10/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import UIKit
import ARKit
import FirebaseFirestore
import DropDown

class ARViewControllerSessionPersistence: UIViewController {
    
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var saveExperienceButton: UIButton!
    @IBOutlet weak var loadExperienceButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var snapshotThumbnail: UIImageView!
    @IBOutlet weak var btnChooseSize: UIButton!
    @IBOutlet weak var btnAddImage: UIButton!
    @IBOutlet weak var btnAddFrame: UIButton!
    
    
    var isRelocalizingMap = false
    var virtualObjectAnchor: ARAnchor?
    var virtualObjectAnchorName = "virtualObject"
    
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        configuration.isLightEstimationEnabled = true
        return configuration
    }()
    
    private let FRAME_NAME = "Frame"
    private let PICTURE_NAME = "Picture"
    
    //MARK : FireBase DB
    let db = Firestore.firestore()
    
    var currentNode:CurrentNodeModel = CurrentNodeModel()
    let imageDataModel = ImageSizeModel()
    var isPickerOpened:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        saveExperienceButton.setup()
        loadExperienceButton.setup()
        loadExperienceButton.isEnabled = true
        loadExperienceButton.isHidden = false
        
        // Do any additional setup after loading the view.
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        // set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        // set debug options
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.automaticallyUpdatesLighting = true
        sceneView.session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
    }
    
    /// - Tag: GetWorldMap
    @IBAction func saveExperience(_ button: UIButton) {
        DispatchQueue.main.async {
            self.sceneView.session.getCurrentWorldMap(completionHandler: {worldMap , error in
                guard let map = worldMap else {print("No Anchor found to capture world map "); return}
                // Add a snapshot image indicating where the map was captured.
                guard let snapshotAnchor = SnapshotAnchor(capturing: self.sceneView)
                    else { fatalError("Can't take snapshot") }
                map.anchors.append(snapshotAnchor)
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: false) else { return}
                let string = data.base64EncodedString()
                guard let nodeInfo = self.currentNode.nodeInfo else {return}
                print(nodeInfo)
                let json = try! JSONEncoder.init().encode(nodeInfo)
                let stringJson = json.base64EncodedString()
                
                let dataDict:[String:String] = ["anchor" : string , "nodeInfo" : stringJson]
                //save node info data and snapanchor
                self.saveData(dataDictinarys: dataDict,forKey: self.virtualObjectAnchorName)
            })
        }
    }
    
    
    /// - Tag: RunWithWorldMap
    @IBAction func loadExperience(_ button: UIButton)  
    {
        let ac = UIAlertController(title: "Enter ID of Anchor to load", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "OK", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
             self.virtualObjectAnchorName = answer.text!
            DispatchQueue.main.async {
                self.resolveAnchorData(forId: self.virtualObjectAnchorName)
            }
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
       
    }
    
    
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        sceneView.session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        isRelocalizingMap = false
        virtualObjectAnchor = nil
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        snapshotThumbnail.isHidden = true
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped),
             (.normal, .extending):
            if frame.anchors.contains(where: { $0.name == virtualObjectAnchorName }) {
                // User has placed an object in scene and the session is mapped, prompt them to save the experience
                message = "Tap 'Save Experience' to save the current map."
            } else {
                message = "Tap on the screen to place an object."
            }
            
        case (.normal, _) where !isRelocalizingMap:
            message = "Move around to map the environment or tap 'Load Experience' to load a saved experience."
            
        case (.normal, _) :
            message = "Move around to map the environment."
            
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            snapshotThumbnail.isHidden = false
            
        default:
            message = trackingState.localizedFeedback
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    // MARK: - Placing AR Content
    
    /// - Tag: PlaceObject
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        // Disable placing objects when the session is still relocalizing
        if isRelocalizingMap && virtualObjectAnchor == nil {
            return
        }
        
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedVerticalPlane])
            .first
            else { return }
        
        // Remove exisitng anchor and add new anchor
        if let existingAnchor = virtualObjectAnchor {
            sceneView.session.remove(anchor: existingAnchor)
        }
        
        let ac = UIAlertController(title: "Enter Unique ID for Anchor", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "OK", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            // do something interesting with "answer" here
            self.virtualObjectAnchorName = answer.text!
            DispatchQueue.main.async {
                self.virtualObjectAnchor = ARAnchor(name: self.virtualObjectAnchorName, transform: hitTestResult.worldTransform)
                self.currentNode = CurrentNodeModel()
                self.sceneView.session.add(anchor: self.virtualObjectAnchor!)
            }
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    
    // MARK: - Function to Save Data to FireBase DB
    func saveData(dataDictinarys : [String:String], forKey : String)  {
        db.collection("roomdecorateDB").document(forKey).setData(dataDictinarys
             ) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    DispatchQueue.main.async {
                        self.loadExperienceButton.isHidden = false
                        self.loadExperienceButton.isEnabled = true
                        self.virtualObjectAnchorName = ""
                    }
                }
        }
    }
    
    // MARK: - Function to Get Data from FireBase DB
    func resolveAnchorData(forId : String){
        let collections = db.collection("roomdecorateDB")
        collections.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                print("cont documets \(querySnapshot!.documents.count)")
                guard let document = querySnapshot?.documents.first(where: {$0.documentID == forId}) else {return }
                
                print("document id = \(document.documentID)")
                let readData = document.data()
                let anchorDataStr:String = readData["anchor"] as! String
                let nodeDataStr:String = readData["nodeInfo"] as! String
                
                guard let dataAnchor = Data.init(base64Encoded: anchorDataStr) else {return}
                guard let dataNode = Data.init(base64Encoded: nodeDataStr) else {return}
                
                guard let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: dataAnchor) else { return }
                    print("world map \(worldMap!)")
                    // Display the snapshot image stored in the world map to aid user in relocalizing.
                    if let snapshotData = worldMap?.snapshotAnchor?.imageData,
                        let snapshot = UIImage(data: snapshotData) {
                        self.snapshotThumbnail.image = snapshot
                    } else {
                        print("No snapshot image in world map")
                    }
                    // Remove the snapshot anchor from the world map since we do not need it in the scene.
                    worldMap?.anchors.removeAll(where: { $0 is SnapshotAnchor })
                    print(worldMap?.anchors)
                    do{
                    print("inside do statement \(dataNode)")
                    let nodeInfoModel  =  try JSONDecoder.init().decode(NodeInfoModel.self, from: dataNode)
                    self.currentNode.nodeInfo = nodeInfoModel
                    print(self.currentNode.nodeInfo!)
                    }
                    catch(let error){ print(error) }
                    let configuration = self.standardConfiguration
                    configuration.initialWorldMap = worldMap
                    self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                    self.isRelocalizingMap = true
                    self.virtualObjectAnchor = nil
                    self.virtualObjectAnchorName = forId
             }
        }
    }
    
    // MARK: - Action Update Frame
    @IBAction func action_addupdateframe(_ sender: UIButton) {
         
        guard let _ = currentNode.node else { return }
        //open image picker to pick any image
        let imagePicker = self.storyboard?.instantiateViewController(withIdentifier: "ImagePickerContrller") as! ImagePickerContrller
        imagePicker.data = imageDataModel.getFrameData()
        imagePicker.delegate = self
        imagePicker.type = .Frame
        self.present(imagePicker, animated: true, completion: nil)
        isPickerOpened = true
    }
    
    // MARK: - Action Update Image
    @IBAction func action_addupdateimage(_ sender: UIButton) {
        
        guard let _ = currentNode.node else { return }
        //open image picker to pick any image
        let imagePicker = self.storyboard?.instantiateViewController(withIdentifier: "ImagePickerContrller") as! ImagePickerContrller
        imagePicker.data = imageDataModel.getData()
        imagePicker.delegate = self
        imagePicker.type = .Picture
        self.present(imagePicker, animated: true, completion: nil)
        isPickerOpened = true
    }
    
    // MARK: - Action Update Size
    
    let model = ImageSizeModel().getFrameData()
    @IBAction func action_selectFrameSize(_ sender: UIButton) {
        
        guard let currNode = currentNode.node else { return }
        guard let modelData = model.first else {return }
        let dropDown = DropDown()
        dropDown.anchorView = sender
        dropDown.direction = .top
        let width = modelData.availablesWidthSize
        let height = modelData.availablesHeightSize
        for i in 0..<(width.count)
        {
            dropDown.dataSource.append(modelData.formatedSize(width: width[i], height: height[i]))
        }
        dropDown.show()
        dropDown.selectionAction = { [unowned self] (index:Int , item:String) in
            // call place image here
            let  widthFactor = CGFloat(width[index]) * 0.0254
            let  heightFactor = CGFloat(height[index]) * 0.0254
            // need to work here
            self.updatePlaneNode(on: currNode, size: CGSize(width: CGFloat(widthFactor), height: CGFloat(heightFactor)))
            self.currentNode.nodeInfo?.nodeHeight = CGFloat(height[index])
            self.currentNode.nodeInfo?.nodeWidth =  CGFloat(width[index])
            for child in (currNode.childNodes){
                if child.name == self.PICTURE_NAME
                {
                    let photoWidth =  widthFactor - 0.0254
                    let photoheight = heightFactor - 0.0254
                    self.updatePlaneNode(on: child, size: CGSize(width: CGFloat(photoWidth), height: CGFloat(photoheight)))
                }
                else if child.name == self.FRAME_NAME{
                    self.updatePlaneNode(on: child, size: CGSize(width: widthFactor, height: heightFactor))
                }
            }
        }
    }
    
    //MARK: - Update Picture and Frame
    func addOrUpdatePicture(picture:UIImage,size : CGSize = CGSize(width: 10.0, height: 10.0))  {
        
        //check for selected node has child or not, if has child , only update frame image size will be same as of frame geometry
        if (currentNode.node?.childNodes.count ?? 0) > 0{
            
            guard let pictureNode = currentNode.node?.childNodes.first(where: {$0.name == PICTURE_NAME}) else {return }
            pictureNode.geometry?.firstMaterial?.diffuse.contents = picture
            //guard let plane = self.findPlaneNode(on: frameNode)!.geometry as? SCNPlane else { return }
        }
        else {
            // size coming in inches and we need to convert it into meters
            let widthInMtrs = (size.width * 0.0254)
            let heightInMtrs = (size.height * 0.0254)
            
            let frameNode = SCNNode(geometry: SCNPlane(width: widthInMtrs , height: heightInMtrs))
            frameNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Frame-01.png")
            frameNode.name = FRAME_NAME
            
            
            let photoWidth =  (frameNode.boundingBox.max.x - frameNode.boundingBox.min.x) - 0.0254
            let photoheight = (frameNode.boundingBox.max.y - frameNode.boundingBox.min.y) - 0.0254
            
            //4. Create A pictureNode Which Will Be Half The Size Of The Wall
            let pictureNode = SCNNode(geometry: SCNPlane(width: CGFloat(photoWidth), height: CGFloat(photoheight)))
            pictureNode.geometry?.firstMaterial?.diffuse.contents = picture
            pictureNode.name = PICTURE_NAME
            
            //Adding nodes to Selected node
            currentNode.node?.addChildNode(pictureNode)
            currentNode.node?.addChildNode(frameNode)
            
            //6. To Prevent Z-Fighting Move The pictureNode Forward Slightly
            //frameNode.position.z = 0.0001
            pictureNode.position.z = -0.0002
            currentNode.node?.geometry = SCNPlane(width: widthInMtrs , height: heightInMtrs)
            currentNode.node?.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        }
    }
    
    //MARK: - Update Picture and Frame
    func addOrUpdateFrame(frame:UIImage,size : CGSize = CGSize(width: 10.0, height: 10.0)) {
        
        //check for selected node has child or not, if has child , only update frame image size will be same as of frame geometry
        if (currentNode.node?.childNodes.count ?? 0) > 0{
            
            guard let frameNode = currentNode.node?.childNodes.first(where: {$0.name == FRAME_NAME}) else {return }
            frameNode.geometry?.firstMaterial?.diffuse.contents = frame
 
        }
        else {
            // size coming in inches and we need to convert it into meters
            let widthInMtrs = (size.width * 0.0254)
            let heightInMtrs = (size.height * 0.0254)
            
            let frameNode = SCNNode(geometry: SCNPlane(width: widthInMtrs , height: heightInMtrs))
            frameNode.geometry?.firstMaterial?.diffuse.contents = frame
            frameNode.name = FRAME_NAME
            
            
            let photoWidth =  (frameNode.boundingBox.max.x - frameNode.boundingBox.min.x) - 0.0254
            let photoheight = (frameNode.boundingBox.max.y - frameNode.boundingBox.min.y) - 0.0254
            
            //4. Create A pictureNode Which Will Be Half The Size Of The Wall
            let pictureNode = SCNNode(geometry: SCNPlane(width: CGFloat(photoWidth), height: CGFloat(photoheight)))
            pictureNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
            pictureNode.name = PICTURE_NAME
            
            //Adding nodes to Selected node
            currentNode.node?.addChildNode(pictureNode)
            currentNode.node?.addChildNode(frameNode)
            
            //6. To Prevent Z-Fighting Move The pictureNode Forward Slightly
            //frameNode.position.z = 0.0001
            pictureNode.position.z = -0.0001
            currentNode.node?.geometry = SCNPlane(width: widthInMtrs , height: heightInMtrs)
            currentNode.node?.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        }
     
    }
    
    func setUpView(virtualNode : VirtualNode , parentNode : SCNNode) {
        
        let widthInMtrs = ((currentNode.nodeInfo?.nodeWidth)! * 0.0254)
        let heightInMtrs = ((currentNode.nodeInfo?.nodeHeight)! * 0.0254)
        
        let frameNode = SCNNode(geometry: SCNPlane(width: widthInMtrs , height: heightInMtrs))
        frameNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: (currentNode.nodeInfo?.nodeFrameImage)!)!
        frameNode.name = FRAME_NAME
        
        
        let photoWidth =  (frameNode.boundingBox.max.x - frameNode.boundingBox.min.x) - 0.0254
        let photoheight = (frameNode.boundingBox.max.y - frameNode.boundingBox.min.y) - 0.0254
        
        //4. Create A pictureNode Which Will Be Half The Size Of The Wall
        let pictureNode = SCNNode(geometry: SCNPlane(width: CGFloat(photoWidth), height: CGFloat(photoheight)))
        pictureNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: (currentNode.nodeInfo?.nodeImage)!)!
        pictureNode.name = PICTURE_NAME
        
        //Adding nodes to Selected node
        virtualNode.addChildNode(pictureNode)
        virtualNode.addChildNode(frameNode)
        
        //6. To Prevent Z-Fighting Move The pictureNode Forward Slightly
        pictureNode.position.z = -0.0001
        virtualNode.geometry = SCNPlane(width: widthInMtrs , height: heightInMtrs)
        virtualNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        
        parentNode.addChildNode(virtualNode)
    }
    
    // MARK: - Function to Find Node
    func findPlaneNode(on node: SCNNode) -> SCNNode? {
        if node.geometry as? SCNPlane != nil {
            return node
        }
        return nil
    }
    
    // MARK: - Function to Update Node Geometry
    func updatePlaneNode(on node: SCNNode, size : CGSize) {
        DispatchQueue.main.async(execute: {
            guard let plane = self.findPlaneNode(on: node)?.geometry as? SCNPlane else { return }
            plane.width = size.width
            plane.height = size.height
        })
    }
    
   
}
extension ARViewControllerSessionPersistence : ARSessionDelegate{
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
        case .extending, .mapped:
            saveExperienceButton.isEnabled =
                virtualObjectAnchor != nil && frame.anchors.contains(virtualObjectAnchor!)
        default:
            saveExperienceButton.isEnabled = false
        }
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking(nil)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
extension ARViewControllerSessionPersistence :ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print(anchor.name)
        print(virtualObjectAnchorName)
        guard anchor.name == virtualObjectAnchorName
            else { return }
        
        // save the reference to the virtual object anchor when the anchor is added from relocalizing
        if virtualObjectAnchor == nil {
            virtualObjectAnchor = anchor
        }
        
        let geometry = SCNPlane(width: 0.1, height:0.1)
        let planeNode = VirtualNode(geometry: geometry)
        planeNode.name = anchor.identifier.uuidString
        planeNode.anchor = anchor
        DispatchQueue.main.async {
            self.currentNode.node = planeNode
            if self.currentNode.nodeInfo != nil{
                self.setUpView(virtualNode: planeNode, parentNode: node)
            } else{
                node.addChildNode(planeNode)
                if self.currentNode.nodeInfo == nil
                {self.currentNode.nodeInfo = NodeInfoModel()}
                self.currentNode.nodeInfo?.nodeWidth = 10.0
                self.currentNode.nodeInfo?.nodeHeight = 10.0
            }
        }
        print("didAdd node called")
    }
}
//MARK: - PROTOCOL CHANGE IMAGE/ FRAME
extension ARViewControllerSessionPersistence : ImageChaneType
{
    func onImageChage(imageData: ImageSizeModel, forType: Type) {
        if currentNode.nodeInfo == nil{currentNode.nodeInfo = NodeInfoModel()}
        switch forType {
        case Type.Frame:
            // call method place image
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.addOrUpdateFrame(frame: UIImage(named: imageData.image!)!)
                self.isPickerOpened = false
                self.currentNode.nodeInfo?.nodeFrameImage = imageData.image
            })
        case Type.Picture:
            // call method place frame
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.addOrUpdatePicture(picture: UIImage(named: imageData.image!)!)
                self.isPickerOpened = false
                self.currentNode.nodeInfo?.nodeImage = imageData.image
            })
        }
    }
}
