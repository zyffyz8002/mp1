//
//  LevelerUIImagePickerController.swift
//  mp1
//
//  Created by Yifan on 7/1/16.
//
//

import Foundation
import CoreLocation
import UIKit
import CoreMotion

class LevelerUIImagePickerController : UIImagePickerController, CLLocationManagerDelegate
{
    var levelerViewController = LevelerViewController()
    
    static var viewNumber = 0
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    func addLevelerViewToOverlayView() {
        if self.cameraOverlayView != nil {
            levelerViewController.view.frame = CGRect(origin: CGPoint(x: 100, y: 0), size: CGSize(width: LevelerParameters.maxRange, height: LevelerParameters.maxRange))
            //levelerViewController
            self.cameraOverlayView!.addSubview(levelerViewController.view)
            levelerViewController.levelerView.shouldDrawBackground = true
            //levelerViewController.addLevelerViewToViewWithRect(toView: self.cameraOverlayView!, withRect: CGRect(origin: CGPoint(x: 100, y: 0), size: CGSize(width: LevelerParameters.maxRange, height: LevelerParameters.maxRange)))
            //levelerViewController.levelerView.shouldDrawBackground = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //levelerViewController.stopUpdateLeveler()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        levelerViewController.stopUpdateLeveler()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        levelerViewController.startUpdateLeveler(nil)
    }
    
}
