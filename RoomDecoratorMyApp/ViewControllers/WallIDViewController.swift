//
//  WallIDViewController.swift
//  RoomDecoratorMyApp
//
//  Created by admin on 15/10/18.
//  Copyright © 2018 NIhilent. All rights reserved.
//

import UIKit

class WallIDViewController: UIViewController {

    @IBOutlet weak var textFieldWallId: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        textFieldWallId.delegate = self
       //view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc func endEditing() {
        view.endEditing(true)
    }

}
extension WallIDViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing()
        return true
    }
}
