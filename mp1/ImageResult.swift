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
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ImageResult")
        request.predicate = NSPredicate(format: "title = %@", title)
        do {
            let results = try context.fetch(request)
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
        if let imageResult = NSEntityDescription.insertNewObject(forEntityName: "ImageResult", into: context) as? ImageResult
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
        threshold = project.threshold as NSNumber?
        latitude = project.latitude as NSNumber?
        longtitude = project.longtidude as NSNumber?
        heading = project.heading as NSNumber?
        autoThreshold = project.autoThreshold as NSNumber?
        isThresholdAutoDecided = project.isThresholdAutoDecided as NSNumber?
        leveldx = project.leveler?.x as NSNumber?
        leveldy = project.leveler?.y as NSNumber?
        skypoints = project.skyPoints as NSNumber?
        nonSkypoints = project.nonSkyPoints as NSNumber?
        lastSavedTime = Date()
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
        project.originalImage = UIImage(data:(originalImageData)! as Data)
        project.edittedImage = UIImage(data:(edittedImageData)! as Data)
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
