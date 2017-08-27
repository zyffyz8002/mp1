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
import QuartzCore

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
    
    @IBAction func showOriginalImage(_ sender: UISwitch) {
        originalImageView.alpha = originalImageAlpha()
    }
    
    
    let imageProcessQueue = OperationQueue()
    
    
    
    @IBAction func sliderChanged(_ sender: UISlider) {
    
        threshold.text = "\(Int(sender.value))"
        let sliderValue = Double(sender.value)
        spinner.startAnimating()
        originalImageView.image = nil
        resultImageView.image = nil
        
        imageProcessQueue.cancelAllOperations()
        let imageBlock = BlockOperation()

        imageBlock.addExecutionBlock {
            [weak self] in
            if sliderValue == Double(sender.value) {
                print("start: \(sender.value)");
                if !imageBlock.isCancelled {
                    self?.imageProcessor.threshold = Double(sender.value)
                    DispatchQueue.main.sync {
                        if sliderValue == Double(sender.value) {
                            self?.updateImage()
                        }
                    }
                }
            }
        }
        imageProcessQueue.addOperation(imageBlock)
    }
    
    fileprivate func presentAlert(_ title: String, message: String) {
        let Alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        Alert.addAction(UIAlertAction(title: "OK", style: .default, handler:  nil))
        self.navigationController!.present(Alert, animated: true, completion: nil)
    }
    
    fileprivate func presentSavingSuccessAlert() {
        /*
        let sucessAlert = UIAlertController(title: "Saving", message: "Saving success!", preferredStyle: UIAlertControllerStyle.Alert)
        sucessAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler:  nil))
        self.navigationController!.presentViewController(sucessAlert, animated: true, completion: nil)
        //self.presentViewController(sucessAlert, animated: true, completion: nil)
        */
        presentAlert("Saving success!", message: "Check your saved photos in SVF album")
    }
    
    fileprivate func presentSavingFailAlert() {
        /*
        let failAlert = UIAlertController(title: "Saving", message: "Saving fail!", preferredStyle: UIAlertControllerStyle.Alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler:  nil))
        self.presentViewController(failAlert, animated: true, completion: nil)
        */
        presentAlert("Saving failed!", message: "Check your photo library privacy setting and try again!")
        
    }
    
    fileprivate func saveProjectToCoreData(to projectContent : ImageResult) -> Bool {
        var success = true
        projectContent.managedObjectContext?.performAndWait {
            if !projectContent.saveProject(withProject: self.imageProject!) {
                //self.presentSavingSuccessAlert()
                success = false
            }
        }
        return success
    }
    
    fileprivate func savePhotoToAlbum() {
        var success = true
        if !customPhotoAlbumManager.savePhoto(withPhoto: imageProject!.originalImage!) {
            success = false
        }
        if !customPhotoAlbumManager.savePhoto(withPhoto: imageProject!.edittedImage!) {
            success = false
        }
        
        if success {
            //presentSavingSuccessAlert()
            presentAlert("Saving success!", message: "Check your saved photos in SVF album")
        } else {
            //presentSavingFailAlert()
            presentAlert("Saving failed!", message: "Check your photo library privacy setting and try again!")
        }
    }
    
    
    fileprivate func saveProject(to projectContent : ImageResult ) {
        if saveProjectToCoreData(to: projectContent) {
            //presentSavingSuccessAlert()
            presentAlert("Saving success!", message: "Your project is saved.")
        } else {
            //presentSavingFailAlert()
            presentAlert("Saving failed!", message: "Your project is not saved.")
        }
        //savePhotoToAlbum()
    }
    
    fileprivate func checkDuplicateAndSaveProject()
    {
        var projectContent : ImageResult?
        
        managedObjectContext?.performAndWait {
            [unowned self] in
            projectContent = ImageResult.getProject(withTitle: self.projectTitle.text!, inManagedObjectContext: self.managedObjectContext!)
        }
        
        if (projectContent != nil) {
            let alert = UIAlertController(title: "Repeated Project", message: "There is already a project named \"\(self.projectTitle.text!)\". Do you want to override it?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction( UIAlertAction(title: "OK",style: .default, handler: { action in self.saveProject(to: projectContent!)}) )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            managedObjectContext?.performAndWait {
                [unowned self] in
                projectContent = ImageResult.createProject(withTitle: self.projectTitle.text!, inManagedObjectContext: self.managedObjectContext!)!
            }
            saveProject(to: projectContent!)
        }
    }
    
    fileprivate func getStringFromOptional(_ string: String?) -> String {
        return string == nil ? "-" : string!
    }
    
    fileprivate func getStringFromOptional(_ double : Double?) -> String {
        return double == nil ? "-" : String(format: "%.2f", double!)
    }
    
    fileprivate func getStringFromOptional(_ double : CGFloat?) -> String {
        return double == nil ? "-" : String(format: "%.2f", double!)
    }
    
    fileprivate func getEmailBody() -> String
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
    
    fileprivate func sendProjectViaEmail() {
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
            present(mailComposerViewController, animated: true, completion: nil)
        } else {
            let mailAlert = UIAlertController(
                title: "E-mail Error" ,
                message: "E-mail cannot be sent!" ,
                preferredStyle:  .alert
            )
            mailAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil) )
            present(mailAlert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func saveResult(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Methods" ,
            message: "Choose the way you want to save this project" ,
            preferredStyle:  .actionSheet
        )
        
        alert.addAction(
            UIAlertAction(title:"Save images to library", style: UIAlertActionStyle.default, handler: {(UIAlertAction) in self.savePhotoToAlbum()})
        )
        
        alert.addAction(
            UIAlertAction(title: "Save To Phone", style: UIAlertActionStyle.default, handler:{ [weak self] (UIAlertAction) in
                self?.checkDuplicateAndSaveProject()
                } )
        )
        alert.addAction(
            UIAlertAction(title: "Email", style: .default, handler: { [weak self] (UIAlertAction) in self?.sendProjectViaEmail() } )
        )
        
        
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel , handler: nil )
        )
        present(alert, animated: true, completion: nil)
    }
    
    var managedObjectContext : NSManagedObjectContext? =
        (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
    
    var imageProject : ImageProject? {
        didSet {
            print("processor passed")
        }
    }
    //private var originalImageAlpha : CGFloat = 1
    fileprivate let imageProcessor = ImageProcessor()
    fileprivate func originalImageAlpha() -> CGFloat {
        var alpha = CGFloat(1)
        switch shouldShowOriginalImage.isOn {
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
    
    fileprivate func updateImage() {
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
    
    fileprivate func setParameters() {
        headingText.text = getStringFromOptional(imageProject?.heading)
        //headingText.text = imageProject!.heading == nil ? "-" : "\(imageProject!.heading!)"
        
        //locationText.text = imageProject!.latitude == nil || imageProject!.longtidude == nil ? "-" : "\(imageProject!.latitude! ), \(imageProject!.longtidude!)"
        locationText.text = getStringFromOptional(imageProject?.latitude) + ", " + getStringFromOptional(imageProject?.longtidude)
        
        if imageProject?.heading != nil {
            levelerView.direction = CGFloat((imageProject!.heading)!)
            levelerView.offset = CGPoint(x: imageProject!.leveler!.x, y: imageProject!.leveler!.y)
        }
    }
    
    fileprivate let customPhotoAlbumManager = CustomPhotoAlbumManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Result"
        self.projectTitle.delegate = self
        
        if imageProject != nil {
            setParameters()
            passImage()
        }
        imageProcessQueue.maxConcurrentOperationCount = 1
        customPhotoAlbumManager.requestForPhotoAlbumAutherization()
        print("result vc view did load")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        projectTitle.resignFirstResponder()
        imageProject?.title = projectTitle.text
        return true
    }
    
    
    @IBAction func processImage(_ sender: UIButton) {
        
        originalImageView.image = nil
        passImage()
    }
    
    fileprivate func passImage() {
        
        spinner.startAnimating()
        if imageProcessor.inputProject == nil {
            if let passedProject = imageProject  {
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                    [weak weakSelf = self] in
                    if passedProject.originalImage == weakSelf!.imageProject!.originalImage {
                        weakSelf!.imageProcessor.inputProject = passedProject
                        //weakSelf!.imageProcessor.processWithDefaultThershold()
                        //weakSelf!.thresholdSlider.value = Float(weakSelf!.imageProcessor.threshold!)
                        DispatchQueue.main.sync {
                            if passedProject.originalImage == weakSelf!.imageProject!.originalImage {
                                weakSelf!.updateImage()
                            } else {
                                weakSelf!.spinner.stopAnimating()
                            }
                        }
                    } else {
                        DispatchQueue.main.sync {
                            weakSelf!.spinner.stopAnimating()
                        }
                        DispatchQueue.main.sync {
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
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
            {
                [weak weakSelf = self] in
                weakSelf?.imageProcessor.processWithDefaultThershold()
                DispatchQueue.main.sync {
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
