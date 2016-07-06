//
//  ImageResult.swift
//  mp1
//
//  Created by Yifan on 6/22/16.
//
//

import Foundation
import CoreData
import UIKit

class ImageResult: NSManagedObject
{
    
    class func getProject(withTitle title: String, inManagedObjectContext context: NSManagedObjectContext) -> ImageResult?
    {
        let request = NSFetchRequest(entityName: "ImageResult")
        request.predicate = NSPredicate(format: "title = %@", title)
        do {
            let results = try context.executeFetchRequest(request)
            if let imageResult = results.first as? ImageResult {
                return imageResult
            }
        } catch let error {
            print("\(error)")
        }

        return nil
    }

    class func createProject(withTitle title :String, inManagedObjectContext context: NSManagedObjectContext) -> ImageResult?
    {
        if let imageResult = NSEntityDescription.insertNewObjectForEntityForName("ImageResult", inManagedObjectContext: context) as? ImageResult
        {
            imageResult.title = title
            return imageResult
        }
        print("Creating core data entity error!")
        return nil
    }
    
    func saveProject(withProject project :ImageProject) -> Bool {
        title = project.title
        originalImageData = UIImagePNGRepresentation(project.originalImage!)
        edittedImageData = UIImagePNGRepresentation(project.edittedImage!)
        threshold = project.threshold
        latitude = project.latitude
        longtitude = project.longtidude
        heading = project.heading
        autoThreshold = project.autoThreshold
        isThresholdAutoDecided = project.isThresholdAutoDecided
        leveldx = project.leveler?.x
        leveldy = project.leveler?.y
        skypoints = project.skyPoints
        nonSkypoints = project.nonSkyPoints
        lastSavedTime = NSDate()
        do {
            try managedObjectContext?.save()
        } catch let error {
            print("saving error: \(error)")
            return false
        }
        return true
    }
    
    func createProject() -> ImageProject {
        let project = ImageProject()
        
        project.title = title
        project.originalImage = UIImage(data:(originalImageData)!)
        project.edittedImage = UIImage(data:(edittedImageData)!)
        project.threshold = threshold?.doubleValue
        project.latitude = latitude?.doubleValue
        project.longtidude = longtitude?.doubleValue
        project.heading = heading?.doubleValue
        project.autoThreshold = autoThreshold?.doubleValue
        project.isThresholdAutoDecided = (isThresholdAutoDecided?.boolValue)!
        if (leveldx != nil) && (leveldy != nil) {
            project.leveler = LevelInformation(x: CGFloat(leveldx!), y: CGFloat(leveldy!))
        } else {
            project.leveler = nil
        }
        project.skyPoints = skypoints?.doubleValue
        project.nonSkyPoints = nonSkypoints?.doubleValue
        return project
    }
}
