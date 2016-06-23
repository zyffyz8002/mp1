//
//  ImageResult.swift
//  mp1
//
//  Created by Yifan on 6/22/16.
//
//

import Foundation
import CoreData


class ImageResult: NSManagedObject {
    
    class func getProject(withTitle title: String, inManagedObjectContext context: NSManagedObjectContext) -> ImageResult?
    {
        let request = NSFetchRequest(entityName: "ImageResult")
        request.predicate = NSPredicate(format: "title = %@", title)
        
        if let imageResult = (try? context.executeFetchRequest(request))?.first as? ImageResult {
            return imageResult
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
}
