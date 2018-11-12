//
//  ImagePickerContrller.swift
//  ARKitImageDetectionTutorial
//
//  Created by admin on 30/08/18.
//  Copyright © 2018 Ivan Nesterenko. All rights reserved.
//

import UIKit

protocol ImageChaneType: class{
    
    func onImageChage(imageData : ImageSizeModel, forType : Type)
}

enum Type:String {
    case Frame
    case Picture
}

class ImagePickerContrller: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    private let CellIdentifier = "imgidentifier"
    var dataArray = [UIImage]()
    var data = [ImageSizeModel]()
    var type:Type = Type.Picture
    weak var delegate : ImageChaneType? = nil
    
    @IBAction func actionCancel(_ sender: UIButton) {
        
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
    }
}
extension ImagePickerContrller : UICollectionViewDelegate,UICollectionViewDataSource
{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        guard let cell:ImageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? ImageViewCell else {
            fatalError("Expected `\(ImageViewCell.self)` type for reuseIdentifier \( CellIdentifier). Check the configuration in Main.storyboard.")
        }
        let image = data[indexPath.row]
        cell.setImage(image: UIImage(named: image.image!)!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.onImageChage(imageData: self.data[indexPath.row], forType: self.type)
         self.dismiss(animated: true, completion: nil)
    }
}


