//
//  ResultsVC.swift
//  mp1
//
//  Created by Sriram Vepuri on 12/31/15.
//
//

import UIKit
import CoreData

class ResultsVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var skyViewFactor: UILabel!
    @IBOutlet weak var threshold: UILabel!
    @IBOutlet weak var originalImageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var projectTitle: UITextField!
    
    @IBAction func showOriginalImage(sender: UISwitch) {
        if sender.on {
            originalImageAlpha = 0.5
        } else {
            originalImageAlpha = 0
        }
        originalImageView.alpha = originalImageAlpha
    }

    @IBAction func sliderChanged(sender: UISlider) {
        threshold.text = "\(Int(sender.value))"
        imageProcessor.threshold = Double(sender.value)
        updateImage()
    }
    
    private func saveProjectToCoreData(to projectContent : ImageResult) {
        projectContent.managedObjectContext?.performBlockAndWait {
            if projectContent.saveProject(withProject: self.imageProject!) {
                let sucessAlert = UIAlertController(title: "Saving", message: "Saving sucess!", preferredStyle: UIAlertControllerStyle.Alert)
                sucessAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler:  nil))
                self.presentViewController(sucessAlert, animated: true, completion: nil)
            } else {
                let failAlert = UIAlertController(title: "Saving", message: "Saving fail!", preferredStyle: UIAlertControllerStyle.Alert)
                failAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler:  nil))
                self.presentViewController(failAlert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func saveResult(sender: UIBarButtonItem) {
        
        var projectContent : ImageResult?
        
        managedObjectContext?.performBlockAndWait {
            [unowned self] in
            projectContent = ImageResult.getProject(withTitle: self.projectTitle.text!, inManagedObjectContext: self.managedObjectContext!)
        }
        
        if (projectContent != nil) {
            let alert = UIAlertController(title: "Repeated Project", message: "There is already a project named \"\(self.projectTitle.text!)\". Do you want to override it?", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction( UIAlertAction(title: "OK",style: .Default, handler: { action in self.saveProjectToCoreData(to: projectContent!)}) )
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else {
            managedObjectContext?.performBlockAndWait {
                [unowned self] in
                projectContent = ImageResult.createProject(withTitle: self.projectTitle.text!, inManagedObjectContext: self.managedObjectContext!)!
            }
            saveProjectToCoreData(to: projectContent!)
        }
    }
    
    var managedObjectContext : NSManagedObjectContext? =
        (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext
    
    var imageProject : ImageProject? {
        didSet {
            print("processor passed")
        }
    }
    private var originalImageAlpha : CGFloat = 0.5
    private let imageProcessor = ImageProcessor()
    private func updateImage() {
        projectTitle.text = imageProject!.title
        if let resultImage = imageProject!.edittedImage {
            resultImageView.image = resultImage
            originalImageView.image = imageProject!.originalImage
            
            originalImageView.alpha = originalImageAlpha
            skyViewFactor.text = String(format: "%.3f", imageProject!.skyViewFactor!)
            thresholdSlider.value = Float(imageProject!.threshold!)
            threshold.text = String(Int(imageProject!.threshold!))
            spinner.stopAnimating()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Result"
        self.projectTitle.delegate = self
        
        passImage()
        print("result vc view did load")
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        projectTitle.resignFirstResponder()
        imageProject?.title = projectTitle.text
        return true
    }
    
    private func passImage() {
        
        spinner.startAnimating()
        if let passedProject = imageProject  {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                [weak weakSelf = self] in
                if passedProject.originalImage == weakSelf!.imageProject!.originalImage {
                    weakSelf!.imageProcessor.inputProject = passedProject
                    //weakSelf!.imageProcessor.processWithDefaultThershold()
                    //weakSelf!.thresholdSlider.value = Float(weakSelf!.imageProcessor.threshold!)
                    dispatch_sync(dispatch_get_main_queue()) {
                        if passedProject.originalImage == weakSelf!.imageProject!.originalImage {
                            weakSelf!.updateImage()
                        } else {
                            weakSelf!.spinner.stopAnimating()
                        }
                    }
                } else {
                    dispatch_sync(dispatch_get_main_queue()) {
                        weakSelf!.spinner.stopAnimating()
                    }
                }
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
