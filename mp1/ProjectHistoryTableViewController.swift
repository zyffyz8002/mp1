//
//  ProjectHistoryTableViewController.swift
//  mp1
//
//  Created by Yifan on 6/30/16.
//
//

import UIKit
import CoreData

class ProjectHistoryTableViewController: CoreDataTableViewController, UISearchBarDelegate
{
    
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.delegate = self
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchText = searchBar.text
        searchBar.resignFirstResponder()
    }
    
    private var searchText : String? {
        didSet {
            updateUI()
        }
    }
    
    var managedObjectContext : NSManagedObjectContext? =
        (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext
    {
        didSet {
            updateUI()
        }
    }
    
    private func updateUI() {
        if let context = managedObjectContext {
            let request = NSFetchRequest(entityName: "ImageResult")
            if searchText != nil {
                request.predicate = NSPredicate(format: "title contains [c] %@", searchText!)
            }
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            self.fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
        } else {
            self.fetchedResultsController = nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProjectInfoCell", forIndexPath: indexPath)
        
        let imageResult = fetchedResultsController?.objectAtIndexPath(indexPath) as? ImageResult
        imageResult?.managedObjectContext?.performBlockAndWait {
            cell.textLabel?.text = imageResult?.title
            cell.detailTextLabel?.text = "\((imageResult?.lastSavedTime)!)"
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let project = fetchedResultsController?.objectAtIndexPath(indexPath) as? ImageResult {
                let managedObjectContext = project.managedObjectContext!
                managedObjectContext.performBlockAndWait {
                    managedObjectContext.deleteObject(project)
                }
                
                do {
                    try managedObjectContext.save()
                } catch let error {
                    print("delete and save error : \(error)")
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let imageResult = fetchedResultsController?.objectAtIndexPath(indexPath) as? ImageResult
        var imageProject = ImageProject()
        imageResult?.managedObjectContext?.performBlockAndWait {
            imageProject = (imageResult?.createProject())!
        }
        performSegueWithIdentifier("ShowResult", sender: imageProject)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("prepare for segue")
        
        if let svc = segue.destinationViewController as? ResultsVC {
            let image = sender as? ImageProject
            svc.imageProject = image
            //svc.originalImage = image***************
        }
    }
}
