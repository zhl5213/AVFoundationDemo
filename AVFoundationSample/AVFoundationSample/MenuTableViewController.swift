//
//  MenuTableViewController.swift
//  AVFoundationSample
//
//  Created by 朱慧林 on 2018/8/18.
//  Copyright © 2018年 朱慧林. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {
    
    let VCClassesId = [
        ("vedioPlayController","load vedio url,play veido"),
        ("VedioCompositionViewController"," vedio composition to a new vedio"),
        ("CameraCaptureViewController"," capture picture from camera"),
        ("UIImagePickerController"," local vedio player "),
        ("QRCodeScanViewController"," QRCode scan "),
        ("ConstraintTestViewController"," Constraint Test ")
        ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return VCClassesId.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = VCClassesId[indexPath.row].0
        cell.detailTextLabel?.text = VCClassesId[indexPath.row].1

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if VCClassesId[indexPath.row].0 == "UIImagePickerController" {
            let vc = UIImagePickerController.init()
            vc.delegate = self
            vc.sourceType = .savedPhotosAlbum
            
            return
        }
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: VCClassesId[indexPath.row].0)
        vc.title = VCClassesId[indexPath.row].0
        navigationController?.pushViewController(vc, animated: true)
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    

}

extension MenuTableViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
    }
    
}
