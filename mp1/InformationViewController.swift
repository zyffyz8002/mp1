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
    
    fileprivate let locationManager = CLLocationManager()
    //private let locationManagerDirection = CLLocationManager()
    
    fileprivate var LatitudeGPS = NSString()
    fileprivate var LongitudeGPS = NSString()
    fileprivate var imageProject = ImageProject()
    
    @IBOutlet var response_label: UILabel!
    
    @IBOutlet var myImageView: UIImageView! {
        didSet {
            myImageView.contentMode = .scaleAspectFit
        }
    }
    //  @IBOutlet var myActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var theta_slider: UISlider!
    @IBOutlet var phi_slider: UISlider!
    @IBOutlet var magLabel: UILabel!
    
    // To display changing Theta value on the app screen
    
    @IBAction func thetaSliderValueChanged(_ sender: UISlider) {
        
        let currentValue = Int(sender.value)
        //print("Slider changing to \(currentValue)")
        
        DispatchQueue.main.async(execute: {
            self.theta_label.text = "\(currentValue)"
        })
        
    }
    
    
    // To display changing Phi value on the app screen
    
    @IBAction func phiSliderValueChanged(_ sender: UISlider) {
        
        let currentValue = Int(sender.value)
        //print("Slider changing to \(currentValue)")
        
        DispatchQueue.main.async(execute: {
            self.phi_label.text = "\(currentValue)"
        })
        
    }
    
    fileprivate var picker = LevelerUIImagePickerController()
       // ProtraitUIImagePickerController()
    
    fileprivate func updateGeoInfoToProject() {
        imageProject.latitude = locationManager.location?.coordinate.latitude
        imageProject.longtidude = locationManager.location?.coordinate.longitude
        imageProject.heading = locationManager.heading?.trueHeading
        if let motionData = motionManager.deviceMotion {
            var xoffset = CGFloat(motionData.attitude.roll)
            let yoffset = CGFloat(motionData.attitude.pitch) //* LevelerParameters.Sensitivity
            xoffset = min(abs(xoffset), 3-abs(xoffset)) * xoffset / abs(xoffset) //* LevelerParameters.Sensitivity
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
            let overlayNewFrame = CGRect(x: 0, y: 0, width: shortSide, height: longSide - PhotoScreenBounds.confirmScreenLowerBound)
            cameraOverlayView.frame = overlayNewFrame
            cameraOverlayView.screenMode = .photoConfirmScreen
        }
    }
    
    @objc func changeToPhotoCatureOverlay(_ picker : UIImagePickerController) {
        if let cameraOverlayView = self.picker.cameraOverlayView as? CameraOverlayView {
            let pickerFrame = self.picker.view.frame
            cameraOverlayView.frame = pickerFrame
            cameraOverlayView.screenMode = .photoCaptureScreen
        }
    }
    
    fileprivate func setCameraPicker() {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == .authorized {
            picker.delegate = self
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            //picker.mediaTypes = .kUTTypeImage
        }
    }
    
    @IBAction func clickedOnCaptureImage() {
        
        print("In clickedOnCaptureImage")
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == .authorized {
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(changeToConfirmScreenOverlay),
                    name: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidCaptureItem"),
                    object: nil
                )
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(changeToPhotoCatureOverlay),
                    name: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidRejectItem"),
                    object: nil
                )
                
                //picker.modalPresentationStyle = UIModalPresentationStyle.FullScreen
                let currentDevice = UIDevice.current
                if !picker.isBeingPresented {
                    present( self.picker, animated: false, completion: {
                        let cameraOverlayViewController = CameraOverlayViewController(nibName: "CameraOverlayViewController", bundle: nil)
                        let cameraOverlayView = cameraOverlayViewController.view as! CameraOverlayView
                        
                        cameraOverlayView.frame = self.picker.view.frame
                        cameraOverlayView.screenMode = .photoCaptureScreen
                        self.picker.cameraOverlayView = cameraOverlayView
                        self.picker.addLevelerViewToOverlayView()
            
                        while (currentDevice.isGeneratingDeviceOrientationNotifications) {
                            currentDevice.endGeneratingDeviceOrientationNotifications()
                        }
                    })
                }
                picker.view.setNeedsLayout()
            }
            
        } else {
            let noCameraPermissionAlert = UIAlertController(title: nil, message: "No permission to camera, please go to setting -> privacy -> camera", preferredStyle: .alert)
            noCameraPermissionAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        }
    }
    
    
    
    @IBAction func clickedOnPhotoLibrary() {
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    fileprivate var displayImage : UIImage? {
        get {
            return myImageView.image
        }
        
        set {
            myImageView.image = newValue
            imageProject.originalImage = newValue
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        switch picker.sourceType {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            if status == .authorized {
                if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    displayImage = UIImage.createSquareImage(fromImage: originalImage)
                }
            }
        case .photoLibrary:
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                displayImage = UIImage.normalizeImage(image)
            }
            
        default:
            break
        }
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func askForCamperaPermission() {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) {
            granted in
            if (granted) {
                print("User allowed camera")
            }  else {
                print("User denied camera")
            }
        }
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let currentDevice = UIDevice.current
        while (currentDevice.isGeneratingDeviceOrientationNotifications) {
            currentDevice.endGeneratingDeviceOrientationNotifications()
        }
     }
    
    @objc fileprivate func printOrientationChange() {
        print("orientation changed")
    }
    
    @IBOutlet weak var levelerView: LevelerView!
    fileprivate var motionManager = CMMotionManager()
    
    fileprivate func startToCheckAttitude() {
        let queue = OperationQueue()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = LevelerParameters.updateInterval
            motionManager.startDeviceMotionUpdates(to: queue)
            {
                [weak weakSelf = self] (data, error) in
                
                guard let motionData = data else {return }
                var xoffset = CGFloat(motionData.attitude.roll)
                let yoffset = CGFloat(motionData.attitude.pitch) * LevelerParameters.sensitivity
                
                xoffset = min(abs(xoffset), 3-abs(xoffset)) * xoffset / abs(xoffset) * LevelerParameters.sensitivity
                
                OperationQueue.main.addOperation {
                    weakSelf?.levelerView.offset = CGPoint(x: xoffset, y:yoffset)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        NotificationCenter.default.addObserver(self, selector: #selector(printOrientationChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        
    }
    
    fileprivate func stopCheckingAttitude()
    {
        motionManager.stopDeviceMotionUpdates()
        
    }
    fileprivate func stopUpdatingLocation()
    {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
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
    
    @IBAction func myImageUploadRequest(_ sender: AnyObject) {
        
        //let imageProcessor = ImageProcessor()
        //imageProcessor.inputImage = myImageView.image
        //imageProcessor.resultImage
        self.performSegue(withIdentifier: "segueToResultsVC", sender: self)
    }
    
    
    // This function is called to take the user to the next screen in the app, when the image processing result is sent by the web server.
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        print("prepare for segue")
        if (segue.identifier == "segueToResultsVC") {
            
            let svc = segue.destination as! ResultsVC;
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //          locationManager.stopUpdatingLocation() 
        //  Stop Location Manager - keep here to run just once
        LatitudeGPS = String(format: "%.2f", manager.location!.coordinate.latitude) as NSString
        LongitudeGPS = String(format: "%.2f", manager.location!.coordinate.longitude) as NSString
        Lat_label.text = LatitudeGPS as String
        Long_label.text = LongitudeGPS as String
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        var h = newHeading.magneticHeading
        let h2 = newHeading.trueHeading // will be -1 if we have no location info
        
        if h2 >= 0 {
            h = h2
        }
        
        let cards = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        var dir = "N"
        
        for (ix, card) in cards.enumerated() {
            if h < 45.0/2.0 + 45.0*Double(ix) {
                dir = card
                break
            }
        }
        
        let concatnatedValue = dir + " " + String(format:"%.2f", h2)
        magLabel.text = concatnatedValue
        
        OperationQueue.main.addOperation {
            
            [weak weakSelf = self] in
            weakSelf?.levelerView.direction = CGFloat(h2)
        }
        
    }
    
}








