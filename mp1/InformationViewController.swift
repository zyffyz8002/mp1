//
//  ViewController.swift
//  mp1
//
//  Created by Sriram Vepuri on 12/11/15.
//
//

import UIKit
import CoreLocation
import AVFoundation
import Foundation
import CoreMotion

class InformationViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet var Lat_label: UILabel!
    @IBOutlet var Long_label: UILabel!
    @IBOutlet var theta_label: UILabel!
    @IBOutlet var phi_label: UILabel!
    
    private let locationManager = CLLocationManager()
    //private let locationManagerDirection = CLLocationManager()
    
    private var LatitudeGPS = NSString()
    private var LongitudeGPS = NSString()
    private var imageProject = ImageProject()
    
    @IBOutlet var response_label: UILabel!
    
    @IBOutlet var myImageView: UIImageView! {
        didSet {
            myImageView.contentMode = .ScaleAspectFit
        }
    }
    //  @IBOutlet var myActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var theta_slider: UISlider!
    @IBOutlet var phi_slider: UISlider!
    @IBOutlet var magLabel: UILabel!
    
    // To display changing Theta value on the app screen
    
    @IBAction func thetaSliderValueChanged(sender: UISlider) {
        
        let currentValue = Int(sender.value)
        //print("Slider changing to \(currentValue)")
        
        dispatch_async(dispatch_get_main_queue(),{
            self.theta_label.text = "\(currentValue)"
        })
        
    }
    
    
    // To display changing Phi value on the app screen
    
    @IBAction func phiSliderValueChanged(sender: UISlider) {
        
        let currentValue = Int(sender.value)
        //print("Slider changing to \(currentValue)")
        
        dispatch_async(dispatch_get_main_queue(),{
            self.phi_label.text = "\(currentValue)"
        })
        
    }
    
    private var picker = LevelerUIImagePickerController()
       // ProtraitUIImagePickerController()
    
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
    
    // This function is called when the user clicks on the button "Capture Image"
    @objc func changeToConfirmScreenOverlay() {
        updateGeoInfoToProject()
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
    }
    
    private func setCameraPicker() {
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if status == .Authorized {
            picker.delegate = self
            picker.sourceType = .Camera
            picker.cameraCaptureMode = .Photo
            //picker.mediaTypes = .kUTTypeImage
        }
    }
    
    @IBAction func clickedOnCaptureImage() {
        
        print("In clickedOnCaptureImage")
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if status == .Authorized {
            if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
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
                
                //picker.modalPresentationStyle = UIModalPresentationStyle.FullScreen
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
            
        } else {
            let noCameraPermissionAlert = UIAlertController(title: nil, message: "No permission to camera, please go to setting -> privacy -> camera", preferredStyle: .Alert)
            noCameraPermissionAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        }
    }
    
    
    
    @IBAction func clickedOnPhotoLibrary() {
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }
    
    private var displayImage : UIImage? {
        get {
            return myImageView.image
        }
        
        set {
            myImageView.image = newValue
            imageProject.originalImage = newValue
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        switch picker.sourceType {
        case .Camera:
            let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
            if status == .Authorized {
                if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    displayImage = UIImage.createSquareImage(fromImage: originalImage)
                }
            }
        case .PhotoLibrary:
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                displayImage = UIImage.normalizeImage(image)
            }
            
        default:
            break
        }
        dismissViewControllerAnimated(true, completion: nil)
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
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let currentDevice = UIDevice.currentDevice()
        while (currentDevice.generatesDeviceOrientationNotifications) {
            currentDevice.endGeneratingDeviceOrientationNotifications()
        }
     }
    
    @objc private func printOrientationChange() {
        print("orientation changed")
    }
    
    @IBOutlet weak var levelerView: LevelerView!
    private var motionManager = CMMotionManager()
    
    private func startToCheckAttitude() {
        let queue = NSOperationQueue()
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = LevelerParameters.UpdateInterval
            motionManager.startDeviceMotionUpdatesToQueue(queue)
            {
                [weak weakSelf = self] (data, error) in
                
                guard let motionData = data else {return }
                var xoffset = CGFloat(motionData.attitude.roll)
                let yoffset = CGFloat(motionData.attitude.pitch) * LevelerParameters.Sensitivity
                
                xoffset = min(abs(xoffset), 3-abs(xoffset)) * xoffset / abs(xoffset) * LevelerParameters.Sensitivity
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    weakSelf?.levelerView.offset = CGPoint(x: xoffset, y:yoffset)
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        startToCheckAttitude()
        updateLocation()
        //startToCheckAttitude()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //print("In viewDidLoad")
        
        askForCamperaPermission()
        setCameraPicker()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(printOrientationChange), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        
    }
    
    private func stopCheckingAttitude()
    {
        motionManager.stopDeviceMotionUpdates()
        
    }
    private func stopUpdatingLocation()
    {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        print("view disapear, disable attitude and location")
        super.viewDidDisappear(animated)
        stopCheckingAttitude()
        stopUpdatingLocation()
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // This function is called when the user clicks on the button "Process Image"
    
    @IBAction func myImageUploadRequest(sender: AnyObject) {
        
        //let imageProcessor = ImageProcessor()
        //imageProcessor.inputImage = myImageView.image
        //imageProcessor.resultImage
        self.performSegueWithIdentifier("segueToResultsVC", sender: self)
    }
    
    
    // This function is called to take the user to the next screen in the app, when the image processing result is sent by the web server.
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        print("prepare for segue")
        if (segue.identifier == "segueToResultsVC") {
            
            let svc = segue.destinationViewController as! ResultsVC;
            svc.imageProject = imageProject
        }
    }
    
    // The following 3 functions are related to the GPS details
    
    func updateLocation() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.locationManager.startUpdatingHeading()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //          locationManager.stopUpdatingLocation() 
        //  Stop Location Manager - keep here to run just once
        LatitudeGPS = String(format: "%.2f", manager.location!.coordinate.latitude)
        LongitudeGPS = String(format: "%.2f", manager.location!.coordinate.longitude)
        Lat_label.text = LatitudeGPS as String
        Long_label.text = LongitudeGPS as String
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        var h = newHeading.magneticHeading
        let h2 = newHeading.trueHeading // will be -1 if we have no location info
        
        if h2 >= 0 {
            h = h2
        }
        
        let cards = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        var dir = "N"
        
        for (ix, card) in cards.enumerate() {
            if h < 45.0/2.0 + 45.0*Double(ix) {
                dir = card
                break
            }
        }
        
        let concatnatedValue = dir + " " + String(format:"%.2f", h2)
        magLabel.text = concatnatedValue
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            
            [weak weakSelf = self] in
            weakSelf?.levelerView.direction = CGFloat(h2)
        }
        
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

extension CMMotionManager {
    
}





