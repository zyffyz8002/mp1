//
//  CaptureOrLibraryViewController.swift
//  mp1
//
//  Created by Yifan on 7/6/16.
//
//

import UIKit
import AVFoundation
import CoreLocation
import CoreMotion

class CaptureOrLibraryViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate
{
    struct storyboardIdentifier {
        static let segueToLibrary = "Choose from library"
        static let segueToResultVC = "Show Result"
    }
    
    @IBAction func capturePhoto(sender: UIButton) {
        askForCamperaPermission()
        presentPickerWithOverlayView()
    }
    
    private var picker = LevelerUIImagePickerController()

    
    private func initCameraPicker() {
        picker.delegate = self

    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        dismissViewControllerAnimated(true, completion: nil)
        switch picker.sourceType {
        case .Camera:
            let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
            if status == .Authorized {
                if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    imageProject.originalImage = UIImage.createSquareImage(fromImage: originalImage)
                    performSegueWithIdentifier(storyboardIdentifier.segueToResultVC, sender: imageProject)
                }
            }
        case .PhotoLibrary:
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imageProject.originalImage  = UIImage.normalizeImage(image)
            }
            
        default:
            break
        }
    }
    
    private func askForCamperaPermission() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) {
            granted in
            if (granted) {
                print("User allowed camera")
            }  else {
                print("User denied camera")
            }
        }
    }
    
    private var imageProject = ImageProject()
    private let locationManager = CLLocationManager()
    private var motionManager = CMMotionManager()
    
    private func updateGeoInfoToProject() {
        imageProject.latitude = locationManager.location?.coordinate.latitude
        imageProject.longtidude = locationManager.location?.coordinate.longitude
        imageProject.heading = locationManager.heading?.trueHeading
        if let motionData = motionManager.deviceMotion {
            var xoffset = CGFloat(motionData.attitude.roll)
            let yoffset = CGFloat(motionData.attitude.pitch) * LevelerParameters.Sensitivity
            xoffset = min(abs(xoffset), 3-abs(xoffset)) * xoffset / abs(xoffset) * LevelerParameters.Sensitivity
            imageProject.leveler = LevelInformation(x: xoffset, y: yoffset)
        } else {
            imageProject.leveler = nil
        }
    }
    
    @objc func changeToConfirmScreenOverlay() {
        updateGeoInfoToProject()
        picker.stopUpdateLeveler()
        if let cameraOverlayView = picker.cameraOverlayView as? CameraOverlayView {
            let pickerFrame = picker.view.frame
            let shortSide = pickerFrame.width < pickerFrame.height ?  pickerFrame.width : pickerFrame.height
            let longSide = pickerFrame.width >= pickerFrame.height ?  pickerFrame.width : pickerFrame.height
            let overlayNewFrame = CGRectMake(0, 0, shortSide, longSide - PhotoScreenBounds.confirmScreenLowerBound)
            cameraOverlayView.frame = overlayNewFrame
            cameraOverlayView.screenMode = .photoConfirmScreen
        }
    }
    
    @objc func changeToPhotoCatureOverlay(picker : UIImagePickerController) {
        if let cameraOverlayView = self.picker.cameraOverlayView as? CameraOverlayView {
            let pickerFrame = self.picker.view.frame
            cameraOverlayView.frame = pickerFrame
            cameraOverlayView.screenMode = .photoCaptureScreen
        }
        //let levelerPicker = picker as? LevelerUIImagePickerController
        self.picker.startUpdateLeveler()
    }
    
    private func addOverlayViewObserver() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(changeToConfirmScreenOverlay),
            name: "_UIImagePickerControllerUserDidCaptureItem",
            object: nil
        )
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(changeToPhotoCatureOverlay),
            name: "_UIImagePickerControllerUserDidRejectItem",
            object: nil
        )
    }
    private func presentPicker() {
        initCameraPicker()
        let currentDevice = UIDevice.currentDevice()
        
        if !picker.isBeingPresented() {
            presentViewController( self.picker, animated: false, completion: {
                let cameraOverlayViewController = CameraOverlayViewController(nibName: "CameraOverlayViewController", bundle: nil)
                let cameraOverlayView = cameraOverlayViewController.view as! CameraOverlayView
                
                cameraOverlayView.frame = self.picker.view.frame
                cameraOverlayView.screenMode = .photoCaptureScreen
                self.picker.cameraOverlayView = cameraOverlayView
                self.picker.locationManager = self.locationManager
                self.picker.motionManager = self.motionManager
                self.picker.addLevelerViewToOverlayView()
                
                while (currentDevice.generatesDeviceOrientationNotifications) {
                    currentDevice.endGeneratingDeviceOrientationNotifications()
                }
            })
        }
        picker.view.setNeedsLayout()
    }
    
    private func presentPickerWithOverlayView() {
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if status == .Authorized {
            if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
                picker.sourceType = .Camera
                picker.cameraCaptureMode = .Photo
                addOverlayViewObserver()
                presentPicker()
            }
        }
        else {
            let noCameraPermissionAlert = UIAlertController(title: "Camera Permission", message: "No permission to camera, please go to setting -> privacy -> camera", preferredStyle: .Alert)
            noCameraPermissionAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
                // Do any additional setup after loading the view.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == storyboardIdentifier.segueToResultVC {
            if let destinationVC = segue.destinationViewController as? ResultsVC {
                if let imageProject = sender as? ImageProject {
                    destinationVC.imageProject = imageProject
                }
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}

struct PhotoScreenBounds {
    static let captureScreenUpperBound : CGFloat = 40
    static let captureScreenLowerBound : CGFloat = 100
    static let confirmScreenLowerBound : CGFloat = 70
    static let confirmScreenUpperBound : CGFloat = 70
}

struct LevelerParameters {
    static let Radius: CGFloat = 5
    static let Sensitivity : CGFloat = 35 / 1.5
    static let UpdateInterval : Double = 0.05
    static let MaxRange : CGFloat = 70
    
}


extension UIImage {
    
    class func createSquareImage(fromImage originalImage: UIImage) -> UIImage {
        let shortSide = originalImage.size.width < originalImage.size.height ? originalImage.size.width : originalImage.size.height
        let longSide = originalImage.size.width >= originalImage.size.height ? originalImage.size.width : originalImage.size.height
        let clipped = (longSide - shortSide) / 2
        let rect = CGRectMake(0, clipped, shortSide, shortSide)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, originalImage.scale)
        originalImage.drawAtPoint(CGPointMake(-rect.origin.x, -rect.origin.y))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    
    class func normalizeImage(image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.drawInRect(CGRect(origin: CGPoint(x:0, y:0), size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}

