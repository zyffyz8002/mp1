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

class LevelerUIImagePickerController : UIImagePickerController, CLLocationManagerDelegate {
    
    static var viewNumber = 0
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    private var levelerView : LevelerView?
    
    var motionManager : CMMotionManager?
    var locationManager : CLLocationManager?
    //var locationManagerDirection : CLLocationManager?
    
    
    private func startToCheckAttitude() {
        let queue = NSOperationQueue()
        if motionManager != nil {
            if motionManager!.deviceMotionAvailable {
                motionManager!.deviceMotionUpdateInterval = LevelerParameters.UpdateInterval
                motionManager!.startDeviceMotionUpdatesToQueue(queue)
                {
                    [unowned weakSelf = self](data, error) in
                    
                    guard let motionData = data else {return }
                    var xoffset = CGFloat(motionData.attitude.roll)
                    let yoffset = CGFloat(motionData.attitude.pitch) * LevelerParameters.Sensitivity
                    
                    xoffset = min(abs(xoffset), 3-abs(xoffset)) * xoffset / abs(xoffset) * LevelerParameters.Sensitivity
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        weakSelf.levelerView!.offset = CGPoint(x: xoffset, y:yoffset)
                    }
                }
            }
        }
    }
    
    func addLevelerViewToOverlayView() {
        if self.cameraOverlayView != nil {
            for subview in (cameraOverlayView?.subviews)! {
                levelerView = subview as? LevelerView
                if levelerView != nil {
                    levelerView?.shouldDrawBackground = true
                    break
                }
            }
        }
        startUpdateLeveler()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        stopUpdateLeveler()
    }
    
    private func updateLocation() {
        if locationManager != nil {
            self.locationManager!.delegate = self
            self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager!.requestWhenInUseAuthorization()
            self.locationManager!.startUpdatingHeading()
        }
    }
    
    func startUpdateLeveler() {
        startToCheckAttitude()
        updateLocation()
    }
    
    func stopUpdateLeveler() {
        motionManager?.stopGyroUpdates()
        locationManager?.stopUpdatingHeading()
        motionManager?.stopDeviceMotionUpdates()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h2 = newHeading.trueHeading // will be -1 if we have no location info
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            
            [weak weakSelf = self] in
            if h2 > 0 {
                if weakSelf?.levelerView != nil {
                    weakSelf?.levelerView!.direction = CGFloat(h2)
                }
            }
        }
    }
    
}