//
//  ImageResult+CoreDataProperties.swift
//  mp1
//
//  Created by Yifan on 6/22/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ImageResult {

    @NSManaged var title: String?
    @NSManaged var originalImageAddress: NSData?
    @NSManaged var edittedImageAddress: NSData?
    @NSManaged var lastSavedTime: NSDate?

}
