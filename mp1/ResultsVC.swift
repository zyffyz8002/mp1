//
//  ResultsVC.swift
//  mp1
//
//  Created by Sriram Vepuri on 12/31/15.
//
//

import UIKit
import CoreData
import MessageUI

class ResultsVC: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var skyViewFactor: UILabel!
    @IBOutlet weak var threshold: UILabel!
    @IBOutlet weak var originalImageView: UIImageView!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var projectTitle: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var headingText: UILabel!
    @IBOutlet weak var levelerView: LevelerView!
    @IBOutlet weak var locationText: UILabel!
    @IBOutlet weak var shouldShowOriginalImage: UISwitch!
    
    @IBAction func showOriginalImage(sender: UISwitch) {
        originalImageView.alpha = originalImageAlpha()
    }
    
    @IBAction func sliderChanged(sender: UISlider) {
        threshold.text = "\(Int(sender.value))"
        let sliderValue = Double(sender.value)
        spinner.startAnimating()
        originalImageView.image = nil
        resultImageView.image = nil
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            [weak self] in
            if sliderValue == Double(sender.value) {
                self?.imageProcessor.threshold = Double(sender.value)
                dispatch_sync(dispatch_get_main_queue()) {
                    if sliderValue == Double(sender.value) {
                        self?.updateImage()
                    }
                }
            }
            
        }
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
    
    private func saveProject()
    {
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
    
    private func getStringFromOptional(string: String?) -> String {
        return string == nil ? "-" : string!
    }
    
    private func getStringFromOptional(double : Double?) -> String {
        return double == nil ? "-" : String(format: "%.2f", double!)
    }
    
    private func getStringFromOptional(double : CGFloat?) -> String {
        return double == nil ? "-" : String(format: "%.2f", double!)
    }
    
    private func getEmailBody() -> String
    {
        
        let body =
            "Sky View Factor : \(getStringFromOptional(imageProject?.skyViewFactor)) \n\n " +
                "Longtitude: \(getStringFromOptional(imageProject?.longtidude)) \n\n" +
                "Latitude: \(getStringFromOptional(imageProject?.latitude)) \n\n" +
                "Magnatic Heading: \(getStringFromOptional(imageProject?.heading)) \n\n" +
                "Level x offset: \(getStringFromOptional(imageProject?.leveler?.x)) \n\n" +
                "Level y offset: \(getStringFromOptional(imageProject?.leveler?.y)) \n\n"
        
        return body
    }
    
    private func sendProjectViaEmail() {
        let mailComposerViewController = MFMailComposeViewController()
        //mailComposerViewController.delegate = self
        mailComposerViewController.mailComposeDelegate = self
        let title = projectTitle.text == nil ? "-" : projectTitle.text!
        mailComposerViewController.setSubject( "Sky View Factor Project : \(title) ")
        mailComposerViewController.setMessageBody (
            getEmailBody()
            ,
            isHTML: false
        )
        
        if let orignialImage = imageProject?.originalImage {
            mailComposerViewController.addAttachmentData(UIImagePNGRepresentation(orignialImage)!, mimeType: "image/PNG", fileName: "OriginalImage.png")
        }
        
        if let edittedImage = imageProject?.edittedImage {
            mailComposerViewController.addAttachmentData(UIImagePNGRepresentation(edittedImage)!, mimeType: "image/PNG", fileName: "EdittedImage.png")
        }
        
        if MFMailComposeViewController.canSendMail() {
            presentViewController(mailComposerViewController, animated: true, completion: nil)
        } else {
            let mailAlert = UIAlertController(
                title: "E-mail Error" ,
                message: "E-mail cannot be sent!" ,
                preferredStyle:  .Alert
            )
            mailAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil) )
            presentViewController(mailAlert, animated: true, completion: nil)
        }
        
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func saveResult(sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Methods" ,
            message: "Choose the way you want to save this project" ,
            preferredStyle:  .ActionSheet
        )
        alert.addAction(
            UIAlertAction(title: "Save To Phone", style: UIAlertActionStyle.Default, handler:{ [weak self] (UIAlertAction) in
                self?.saveProject()
                } )
        )
        alert.addAction(
            UIAlertAction(title: "Email", style: .Default, handler: { [weak self] (UIAlertAction) in self?.sendProjectViaEmail() } )
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .Cancel , handler: nil )
        )
        presentViewController(alert, animated: true, completion: nil)
    }
    
    var managedObjectContext : NSManagedObjectContext? =
        (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext
    
    var imageProject : ImageProject? {
        didSet {
            print("processor passed")
        }
    }
    //private var originalImageAlpha : CGFloat = 1
    private let imageProcessor = ImageProcessor()
    private func originalImageAlpha() -> CGFloat {
        var alpha = CGFloat(1)
        switch shouldShowOriginalImage.on {
        case true:
            if imageProject?.edittedImage != nil {
                alpha = 0.5
            } else {
                alpha = 1
            }
        case false:
            alpha = 0
        }
        return alpha
    }
    private func updateImage() {
        projectTitle.text = imageProject!.title
        originalImageView.image = imageProject!.originalImage
        originalImageView.alpha = originalImageAlpha()
        
        if let resultImage = imageProject!.edittedImage {
            resultImageView.image = resultImage
            
            skyViewFactor.text = String(format: "%.3f", imageProject!.skyViewFactor!)
            thresholdSlider.value = Float(imageProject!.threshold!)
            threshold.text = String(Int(imageProject!.threshold!))
            spinner.stopAnimating()
        }
    }
    
    private func setParameters() {
        headingText.text = getStringFromOptional(imageProject?.heading)
        //headingText.text = imageProject!.heading == nil ? "-" : "\(imageProject!.heading!)"
        
        //locationText.text = imageProject!.latitude == nil || imageProject!.longtidude == nil ? "-" : "\(imageProject!.latitude! ), \(imageProject!.longtidude!)"
        locationText.text = getStringFromOptional(imageProject?.latitude) + ", " + getStringFromOptional(imageProject?.longtidude)
        
        if imageProject?.heading != nil {
            levelerView.direction = CGFloat((imageProject!.heading)!)
            levelerView.offset = CGPoint(x: imageProject!.leveler!.x, y: imageProject!.leveler!.y)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Result"
        self.projectTitle.delegate = self
        
        if imageProject != nil {
            setParameters()
            passImage()
        }
        print("result vc view did load")
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        projectTitle.resignFirstResponder()
        imageProject?.title = projectTitle.text
        return true
    }
    
    
    @IBAction func processImage(sender: UIButton) {
        
        originalImageView.image = nil
        passImage()
    }
    
    private func passImage() {
        
        spinner.startAnimating()
        if imageProcessor.inputProject == nil {
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
                        dispatch_sync(dispatch_get_main_queue()) {
                            if passedProject.originalImage == weakSelf!.imageProject!.originalImage {
                                weakSelf!.updateImage()
                            } else {
                                weakSelf!.spinner.stopAnimating()
                            }
                        }
                    }
                }
            }
        } else {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
            {
                [weak weakSelf = self] in
                weakSelf?.imageProcessor.processWithDefaultThershold()
                dispatch_sync(dispatch_get_main_queue()) {
                    weakSelf!.updateImage()
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
