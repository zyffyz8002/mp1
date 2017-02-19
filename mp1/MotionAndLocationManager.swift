//
//  MotionAndLocationManager.swift
//  mp1
//
//  Created by Yifan on 7/14/16.
//
//

import Foundation
import CoreLocation
import CoreMotion

class MotionAndLocationManager : NSObject, CLLocationManagerDelegate {
    
    static func requestAutherization() {
        locationManager.requestWhenInUseAuthorization()
    }
    static var motionManager : CMMotionManager {
        get {
            if _motionManager == nil {
                _motionManager = CMMotionManager()
            }
            return _motionManager!
        }
    }
    
    static var locationManager : CLLocationManager {
        get {
            if _locationManager == nil {
                _locationManager = CLLocationManager()
            }
            return _locationManager!
        }
    }
    
    static var locationManagerDelegate : CLLocationManagerDelegate? {
        get {
            return locationManager.delegate
        }
        set {
            locationManager.delegate = newValue
        }
    }
    
    fileprivate static var _motionManager : CMMotionManager?
    fileprivate static var _locationManager : CLLocationManager?

    static var motionData : CMDeviceMotion? {
        get {
            return motionManager.deviceMotion
        }
    }
    
    static var heading : Double? {
        get {
            return locationManager.heading?.trueHeading
        }
    }
    
    static var latitude : Double? {
        get {
            return locationManager.location?.coordinate.latitude
        }
    }
    
    static var longtitude : Double? {
        get {
            return locationManager.location?.coordinate.longitude
        }
    }

    static func startToCheckAttitude( _ motionHandler: ((CMDeviceMotion?, Error?)->())? ) {
    
        if motionHandler == nil { return }
        let queue = OperationQueue()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = LevelerParameters.updateInterval
            motionManager.startDeviceMotionUpdates(to: queue, withHandler: motionHandler!)
        }
    }

    static func updateHeading() {
        
        //MotionAndLocationManager.locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //LevelerViewController.locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading()
        
        
    }
    
    static func stopUpdateHeading() {
        locationManager.stopUpdatingHeading()
    }
    
    static func stopUpdateAttitude() {
        motionManager.stopDeviceMotionUpdates()
    }

}





























