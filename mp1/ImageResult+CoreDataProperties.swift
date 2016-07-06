//
//  ImageResult+CoreDataProperties.swift
//  mp1
//
//  Created by Yifan on 7/1/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ImageResult {

    @NSManaged var edittedImageData: NSData?
    @NSManaged var lastSavedTime: NSDate?
    @NSManaged var originalImageData: NSData?
    @NSManaged var title: String?
    @NSManaged var longtitude: NSNumber?
    @NSManaged var leveldx: NSNumber?
    @NSManaged var leveldy: NSNumber?
    @NSManaged var threshold: NSNumber?
    @NSManaged var autoThreshold: NSNumber?
    @NSManaged var isThresholdAutoDecided: NSNumber?
    @NSManaged var skypoints: NSNumber?
    @NSManaged var nonSkypoints: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var heading: NSNumber?

}
