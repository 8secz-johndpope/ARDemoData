//
//  ARViewController.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 18/09/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import DropDown
import FirebaseFirestore
import PopupDialog

class ARViewControllerPersistence: UIViewController, ARSCNViewDelegate,ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var btnChooseSize: UIButton!
    @IBOutlet weak var btnAddImage: UIButton!
    @IBOutlet weak var btnAddFrame: UIButton!
 
    
    @IBOutlet weak var lblTrackingStatus: UILabel!
    
    
    @IBOutlet weak var imgSnapShot: UIImageView!
    
    
     
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.nihilent.RoomDecoratorMyApp.serialSceneKitQueue")
    
    let session = ARSession()
    let imageDataModel = ImageSizeModel()
    var isPickerOpened:Bool = false
    var nodeArray:[VirtualNode] = [VirtualNode]()
    var selectedNode : VirtualNode? = nil
 
 
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
    
    var virtualObjectAnchor: ARAnchor?
    var savedData:NodeInfoModel?
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        
        sceneView.session = self.session
        //set up camera
        setupCamera()
        // set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        // set debug options
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.automaticallyUpdatesLighting = true
        
        //MARK: - Adding Tap Gestures to select Node
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gesture:)))
        tapGesture.numberOfTapsRequired  = 2
        sceneView.addGestureRecognizer(tapGesture)
        
        
        let tapGestureAddAnchor = UITapGestureRecognizer(target: self, action: #selector(self.handleTapAddAnchor(gesture:)))
        tapGestureAddAnchor.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureAddAnchor)
        
        //let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.onNodeSelected(gesture:)))
        //sceneView.addGestureRecognizer(pressGesture)
        
        // Tracks pans on the screen
        //let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        //sceneView.addGestureRecognizer(panGesture)
        
        //let configuration = sceneView.session.getConfiguration()
        
        //uncomment this
        sceneView.session.run(standardConfiguration, options: [.removeExistingAnchors, .resetTracking])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: - Scene content setup
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        //blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            //self.blurView.isHidden = true
            //self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Action Save Session Achor
    @IBAction func action_SaveMyDecoration(_ sender: UIButton) {
        //ask for unique id
      
        DispatchQueue.main.async {
            self.sceneView.session.getCurrentWorldMap(completionHandler: {worldMap , error in
                guard let map = worldMap else {print("No Anchor found to capture world map "); return}
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: false) else { return}
                let string = data.base64EncodedString()
                print("unique ID",121)
                //guard let node = self.selectedNode else {return}
                self.saveData(dataString: string,forKey: "121")
            })
        }
        
    }
    
    // MARK: - Action Update Frame
    @IBAction func action_addupdateframe(_ sender: UIButton) {
        if nodeArray.count == 0 {return}
        guard let _ = selectedNode else { return }
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
        if nodeArray.count == 0{return}
        guard let _ = selectedNode else { return }
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
        
        guard let node = selectedNode else { return }
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
            self.updatePlaneNode(on: node, size: CGSize(width: CGFloat(widthFactor), height: CGFloat(heightFactor)))
            for child in node.childNodes{
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
    
    //MARK: - rstart session to detect new plane and render node
    @IBAction func action_renderPlaneOnWall(_ sender: UIButton) {
        //self.sceneView.session.run(standardConfiguration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    //MARK: - Resolve Saved Anchor
    @IBAction func resolveSavedAnchor(_ sender: UIButton) {
        //ask for unique id
        self.resolveAnchorData(forId: "121")
    }
    
    
    // MARK: - Function to Save Data to FireBase DB
    func saveData(dataString : String, forKey : String)  {
          db.collection("roomdecorateDB").document(forKey).setData([
            "anchor": dataString]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        
     }
    
     // MARK: - Function to Get Data from FireBase DB
    func resolveAnchorData(forId : String){
        let collections = db.collection("roomdecorateDB")
        //let document =  collections.document("roomDecorateDocument")
        collections.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                print("cont documets \(querySnapshot!.documents.count)")
                guard let document = querySnapshot?.documents.first(where: {$0.documentID == forId}) else {return }
                
                    print("document id = \(document.documentID)")
                    let readData = document.data()
                    let anchorDataStr:String = readData["anchor"] as! String
                    guard let data = Data.init(base64Encoded: anchorDataStr) else {return}
                    print("After data\(data)")
                    if let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                            print("world map \(worldMap!)")
                        // Display the snapshot image stored in the world map to aid user in relocalizing.
                        if let snapshotData = worldMap?.snapshotAnchor?.imageData,
                            let snapshot = UIImage(data: snapshotData) {
                            self.imgSnapShot.image = snapshot
                        } else {
                            print("No snapshot image in world map")
                        }
                        // Remove the snapshot anchor from the world map since we do not need it in the scene.
                        worldMap?.anchors.removeAll(where: { $0 is SnapshotAnchor })
                        
                        let configuration = self.standardConfiguration // this app's standard world tracking settings
                        configuration.initialWorldMap = worldMap
                        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                        } else { print("Could not decode") }
                    }
            }
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
    
    
    //MARK: - Find SCNNode at Position
    //For now we are not using this method to find a node
    private func node(at position: CGPoint) -> SCNNode? {
        let hitTestResults: [SCNHitTestResult] = sceneView.hitTest(position, options: nil)
        let selectedNode = nodeArray.first(where: {$0.name == hitTestResults.first?.node.name || $0.name == hitTestResults.first?.node.parent?.name})
        return  selectedNode
    }
    
    //MARK: - Create new SCNode to display when wall detected
    fileprivate func createFrameNode(anchor:ARPlaneAnchor) ->SCNNode{
        let frameNode = SCNNode(geometry: SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z)))
        frameNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        frameNode.eulerAngles.x = -.pi/2
        return frameNode
    }
    
     override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    //MARK: - perform hit test on location to find the node at location
    @objc func handleTap(gesture : UITapGestureRecognizer)  {
        
        let location = gesture.location(in: self.sceneView)
        self.selectedNode = findNodeAtLocation(at: location) // update here
        
        guard let node = selectedNode else { return }
        node.react()
        print(selectedNode ?? "not found")
    }
    
    //MARK: - perform hit test to put an Anchor
    @objc func handleTapAddAnchor(gesture : UITapGestureRecognizer)  {
        
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(gesture.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedVerticalPlane])
            .first
            else { return }
        
        // Remove exisitng anchor and add new anchor
        if let existingAnchor = virtualObjectAnchor {
            sceneView.session.remove(anchor: existingAnchor)
        }
        virtualObjectAnchor = ARAnchor(name: "121", transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: virtualObjectAnchor!)
    }
    
    //MARK: - Long Press Gesture to Select Node
    @objc func onNodeSelected(gesture : UILongPressGestureRecognizer)  {
        
        let location = gesture.location(in: self.sceneView)
        self.selectedNode = findNodeAtLocation(at: location) // update here
        
        guard let node = selectedNode else { return }
        // get its material
        node.react()
        print(selectedNode ?? "not found")
    }
    
    
    //MARK: - Find Node at Location
    func findNodeAtLocation(at location : CGPoint)-> VirtualNode?{
        let results = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        // closest hit anchor
        guard let anchor = results.first?.anchor else {return nil}
        
        // corresponding node
        guard let node = sceneView.node(for: anchor) else {return nil}
        print("planeHitTest  ",node.childNodes)
        
        if node.isKind(of: VirtualNode.self)
        {
            let virtualNode = node as? VirtualNode
            return virtualNode
        }
        else {
            // Search a child node which has a plane geometry
            for child in node.childNodes {
                guard let virtualNode = child as? VirtualNode else {continue}
                print("planeHitTest",virtualNode)
                return virtualNode
             }
        }
        return nil
    }
    
    
    //MARK: - Update Picture and Frame
    func addOrUpdatePicture(picture:UIImage,size : CGSize = CGSize(width: 10.0, height: 10.0))  {
        
        //check for selected node has child or not, if has child , only update frame image size will be same as of frame geometry
        if (selectedNode?.childNodes.count ?? 0) > 0{
            
            guard let pictureNode = selectedNode?.childNodes.first(where: {$0.name == PICTURE_NAME}) else {return }
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
            selectedNode?.addChildNode(pictureNode)
            selectedNode?.addChildNode(frameNode)
            
            //6. To Prevent Z-Fighting Move The pictureNode Forward Slightly
            //frameNode.position.z = 0.0001
            pictureNode.position.z = -0.0002
            selectedNode?.geometry = SCNPlane(width: widthInMtrs , height: heightInMtrs)
            selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        }
    }
    
    //MARK: - Update Picture and Frame
    func addOrUpdateFrame(frame:UIImage,size : CGSize = CGSize(width: 10.0, height: 10.0)) {
        
        //check for selected node has child or not, if has child , only update frame image size will be same as of frame geometry
        if (selectedNode?.childNodes.count ?? 0) > 0{
            
            guard let frameNode = selectedNode?.childNodes.first(where: {$0.name == FRAME_NAME}) else {return }
            frameNode.geometry?.firstMaterial?.diffuse.contents = frame
            //guard let plane = self.findPlaneNode(on: frameNode)!.geometry as? SCNPlane else { return }
            
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
        selectedNode?.addChildNode(pictureNode)
        selectedNode?.addChildNode(frameNode)
        
        //6. To Prevent Z-Fighting Move The pictureNode Forward Slightly
        //frameNode.position.z = 0.0001
         pictureNode.position.z = -0.0001
        selectedNode?.geometry = SCNPlane(width: widthInMtrs , height: heightInMtrs)
        selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        }
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("didAdd called")
        
        guard anchor.name == "121"
            else { return }
        
        // save the reference to the virtual object anchor when the anchor is added from relocalizing
        if virtualObjectAnchor == nil {
            virtualObjectAnchor = anchor
        }
        
        // check here for if node is available
       //   if !nodeArray.contains(where: { $0.name == anchor.identifier.uuidString}){
        print("Not found")
        //let planeNode = createFrameNode(anchor: planeAnchor)
        let geometry = SCNPlane(width: 0.1, height: 0.1)
        let planeNode = VirtualNode(geometry: geometry)
        planeNode.name = anchor.identifier.uuidString
        planeNode.anchor = anchor
        DispatchQueue.main.async {
            node.addChildNode(planeNode)
            self.nodeArray.append(planeNode)
            }
     //     }
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            lblTrackingStatus.text = camera.trackingState.presentationString
        case .normal:
            // Unhide content after successful relocalization.
            lblTrackingStatus.text = camera.trackingState.presentationString
         }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
           self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
 
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
         switch frame.worldMappingStatus {
        case .extending, .mapped:
        print("extending / mapped")
        default:
            print( "Still mapping")
            
        }
    }
    
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    
}
    //MARK: - PROTOCOL CHANGE IMAGE/ FRAME
extension ARViewControllerPersistence : ImageChaneType
{
    func onImageChage(imageData: ImageSizeModel, forType: Type) {
        
        switch forType {
        case Type.Frame:
            // call method place image
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.addOrUpdateFrame(frame: imageData.image!)
                 self.isPickerOpened = false
            })
        case Type.Picture:
            // call method place frame
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.addOrUpdatePicture(picture: imageData.image!)
                  self.isPickerOpened = false
            })
        }
    }
}

