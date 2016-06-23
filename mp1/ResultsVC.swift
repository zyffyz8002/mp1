//
//  ResultsVC.swift
//  mp1
//
//  Created by Sriram Vepuri on 12/31/15.
//
//

import UIKit
import CoreData

class ResultsVC: UIViewController {

    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var skyViewFactor: UILabel!
    @IBOutlet weak var threshold: UILabel!
    @IBOutlet weak var originalImageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var projectTitle: UITextField!
    
    @IBAction func showOriginalImage(sender: UISwitch) {
        if sender.on {
            originalImageView.alpha = 0.5
        } else {
            originalImageView.alpha = 0
        }
    }

    @IBAction func sliderChanged(sender: UISlider) {
        threshold.text = "\(Int(sender.value))"
        imageProcessor.threshold = Double(sender.value)
        updateImage()
    }
    
    @IBAction func saveResult(sender: UIBarButtonItem) {
        // error if no images to save
        let originalImageData = UIImagePNGRepresentation(originalImageView.image!)
        let edittedImageData = UIImagePNGRepresentation(resultImageView.image!)
        
        managedObjectContext?.performBlock {
            var override = false
            var imageResult = ImageResult.getProject(withTitle: self.projectTitle.text!, inManagedObjectContext: self.managedObjectContext!)
            if (imageResult != nil) {
                
                let alert = UIAlertController(title: "Repeated Project", message: "There is already a project named \(self.projectTitle.text). Do you want to override it?", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction) in
                    override = true
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {(action: UIAlertAction) in override = false} ))
                
                dispatch_async(dispatch_get_main_queue()) {
                            
                }
            } else {
                override = true
                ImageResult.createProject(withTitle: self.projectTitle.text!, inManagedObjectContext: self.managedObjectContext!)
            }
            
            if (override) {
                imageResult?.edittedImageAddress = edittedImageData
                imageResult?.originalImageAddress = edittedImageData
            }
            
        }
    }
    
    var managedObjectContext : NSManagedObjectContext? =
        (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext
    
    var originalImage : UIImage?
    private let imageProcessor = ImageProcessor()
    
    private func updateImage() {
        if let resultImage = imageProcessor.resultImage {
            spinner.stopAnimating()
            resultImageView.image = resultImage
            originalImageView.image = originalImage
            originalImageView.alpha = 0.5
            skyViewFactor.text = String(format: "%.3f", imageProcessor.skyViewFactor!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Result"
        passImage()
    }
    
    private func passImage() {
        
        spinner.startAnimating()
        if let passedImage = originalImage  {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                [weak weakSelf = self] in
                if passedImage == weakSelf!.originalImage {
                    weakSelf!.imageProcessor.inputImage = passedImage
                    weakSelf!.imageProcessor.processWithDefaultThershold()
                    weakSelf!.thresholdSlider.value = Float(weakSelf!.imageProcessor.threshold)
                    dispatch_sync(dispatch_get_main_queue()) {
                        if passedImage == weakSelf!.originalImage{
                            weakSelf!.updateImage()
                        } else {
                            weakSelf!.spinner.stopAnimating()
                        }
                    }
                } else {
                    weakSelf!.spinner.stopAnimating()
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
