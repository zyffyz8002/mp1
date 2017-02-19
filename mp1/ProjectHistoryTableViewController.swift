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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchText = searchBar.text
        searchBar.resignFirstResponder()
    }
    
    fileprivate var searchText : String? {
        didSet {
            updateUI()
        }
    }
    
    var managedObjectContext : NSManagedObjectContext? =
        (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
    {
        didSet {
            updateUI()
        }
    }
    
    fileprivate func updateUI() {
        if let context = managedObjectContext {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ImageResult")
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectInfoCell", for: indexPath)
        
        let imageResult = fetchedResultsController?.object(at: indexPath) as? ImageResult
        imageResult?.managedObjectContext?.performAndWait {
            cell.textLabel?.text = imageResult?.title
            cell.detailTextLabel?.text = "\((imageResult?.lastSavedTime)!)"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let project = fetchedResultsController?.object(at: indexPath) as? ImageResult {
                let managedObjectContext = project.managedObjectContext!
                managedObjectContext.performAndWait {
                    managedObjectContext.delete(project)
                }
                
                do {
                    try managedObjectContext.save()
                } catch let error {
                    print("delete and save error : \(error)")
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let imageResult = fetchedResultsController?.object(at: indexPath) as? ImageResult
        var imageProject = ImageProject()
        imageResult?.managedObjectContext?.performAndWait {
            imageProject = (imageResult?.createProject())!
        }
        performSegue(withIdentifier: "ShowResult", sender: imageProject)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare for segue")
        
        if let svc = segue.destination as? ResultsVC {
            let image = sender as? ImageProject
            svc.imageProject = image
            //svc.originalImage = image***************
        }
    }
}
