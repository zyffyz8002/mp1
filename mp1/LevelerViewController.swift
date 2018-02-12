//
//  LevelerViewController.swift
//  mp1
//
//  Created by Yifan on 7/13/16.
//
//

import UIKit
import CoreLocation
import CoreMotion

class LevelerViewController : UIViewController, CLLocationManagerDelegate {
    
    //let levelerView = LevelerView()
    
    //@IBOutlet weak var levelerView: LevelerView!
    
    //@IBOutlet var levelerView: LevelerView!
    //@IBOutlet var levelerView: LevelerView!
    //let levelerView = LevelerView()
    
    @IBOutlet weak var levelerView: LevelerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("levelerVIewController did load")
       // levelerView.frame = view.bounds
       // view.addSubview(levelerView)
    }
    
    func addLevelerViewToViewWithRect(toView view: UIView, withRect rect: CGRect) {
        let side = min(rect.width, rect.height)
        levelerView.frame = CGRect(origin: rect.origin, size: CGSize(width: side, height: side))
        //levelerView.scale = side / LevelerParameters.maxRange
        view.addSubview(levelerView)
    }
    
    static func getLevelInformationFromMotionData(_ motionData : CMDeviceMotion?) -> LevelInformation? {
        if motionData == nil {return nil}
        var xoffset = CGFloat(motionData!.attitude.roll)
        let yoffset = CGFloat(motionData!.attitude.pitch) * LevelerParameters.sensitivity
        xoffset = min(abs(xoffset), 3-abs(xoffset)) * xoffset / abs(xoffset) * LevelerParameters.sensitivity
        
        return LevelInformation(x: xoffset, y: yoffset)
    }
    
    static func leveled(_ data : CMDeviceMotion?) -> Bool {
        if let offset = getLevelInformationFromMotionData(data) {
            let distance = pow(pow(offset.x, 2) + pow(offset.y, 2), 0.5)
            if distance <= LevelerParameters.thresholdRadius {
                return true
            }
        }
        return false
    }
    
    fileprivate func updateHeadingInLevelerView( ) {
        
        MotionAndLocationManager.locationManagerDelegate = self
        MotionAndLocationManager.updateHeading()
    }
    
    fileprivate func updateAttidueInLevelerView( _ levelHandler : (( CMDeviceMotion?, Error?) -> ())? )
    {
        MotionAndLocationManager.startToCheckAttitude { (data, error) in
            guard let motionData = data else {return }
            if let levelInformation = LevelerViewController.getLevelInformationFromMotionData(motionData)
            {
                let offset = CGPoint(x: levelInformation.x, y: levelInformation.y)
                
                OperationQueue.main.addOperation {
                    self.levelerView.offset = offset
                }
                levelHandler?(data, error)
            }

        }
    }
    
    func startUpdateLeveler( _ levelHandler : (( CMDeviceMotion?, Error?) -> ())? ) {

        updateAttidueInLevelerView( levelHandler )
        updateHeadingInLevelerView()
    }
    
    func stopUpdateLeveler() {

        MotionAndLocationManager.stopUpdateHeading()
        MotionAndLocationManager.stopUpdateAttitude()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h2 = newHeading.trueHeading // will be -1 if we have no location info
        
        OperationQueue.main.addOperation {
            
            [weak weakSelf = self] in
            if h2 > 0 {
                if weakSelf?.levelerView != nil {
                    weakSelf?.levelerView.direction = CGFloat(h2)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}
