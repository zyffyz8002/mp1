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

class InformationViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet var Lat_label: UILabel!
    @IBOutlet var Long_label: UILabel!
    
    @IBOutlet var theta_label: UILabel!
    @IBOutlet var phi_label: UILabel!
    
    let locationManager = CLLocationManager()
    let locationManagerDirection = CLLocationManager()
    
    var LatitudeGPS = NSString()
    var LongitudeGPS = NSString()
    
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
    
    
    // This function is called when the user clicks on the button "Capture Image"
    
    @IBAction func clickedOnCaptureImage() {
        
        print("In clickedOnCaptureImage")
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if status == .Authorized {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .Camera
            //picker.showsCameraControls = false
            picker.allowsEditing = true
            picker.cameraCaptureMode = .Photo
            presentViewController(picker, animated: true, completion: nil)
        } else {
            let noCameraPermissionAlert = UIAlertController(title: nil, message: "No permission to camera, please go to setting -> privacy -> camera", preferredStyle: .Alert)
            noCameraPermissionAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            //presentViewController(noCameraPermissionAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func clickedOnPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        switch picker.sourceType {
        case .Camera:
            let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
            if status == .Authorized {
                self.myImageView.image = info[UIImagePickerControllerEditedImage] as? UIImage
            }
        case .PhotoLibrary:
            self.myImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("In viewDidLoad")
        updateLocation()
        askForCamperaPermission()
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
            svc.originalImage = myImageView.image
            
        }
    }
    
    // The following 3 functions are related to the GPS details
    
    func updateLocation() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //self.locationManager.distanceFilter = 10
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.locationManager.startUpdatingHeading()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //          locationManager.stopUpdatingLocation() // Stop Location Manager - keep here to run just once
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
        
        let concatnatedValue = dir + " " + String(format:"%.2f", h)
        magLabel.text = concatnatedValue
        //print(concatnatedValue)
        
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


