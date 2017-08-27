//
//  ImageProject.swift
//  mp1
//
//  Created by Yifan on 7/1/16.
//
//

import Foundation
import UIKit


class ImageProject {
    var title : String?
    var originalImage : UIImage? {
        didSet {
            clearEdittedImageInformation()
        }
    }
    var edittedImage : UIImage?
    var threshold : Double?
    var latitude : Double?
    var longtidude : Double?
    var isThresholdAutoDecided = true
    var leveler : LevelInformation?
    var heading : Double?
    var autoThreshold : Double?
    var skyPoints : Double?
    var nonSkyPoints : Double?
    
    var skyViewFactor : Double? {
        get {
            if (skyPoints != nil && nonSkyPoints != nil) {
                return skyPoints! / (skyPoints! + nonSkyPoints!)
            } else {
                return nil
            }
        }
    }
    
    fileprivate func clearEdittedImageInformation() {
        edittedImage = nil
        threshold = nil
        autoThreshold = nil
        skyPoints = nil
        nonSkyPoints = nil
    }
    
    func updateGeoInfo() {
        latitude = MotionAndLocationManager.latitude
        longtidude = MotionAndLocationManager.longtitude
        heading = MotionAndLocationManager.heading
        leveler = LevelerViewController.getLevelInformationFromMotionData(MotionAndLocationManager.motionData)
    }
}

struct LevelInformation {
    var x : CGFloat
    var y : CGFloat
}
