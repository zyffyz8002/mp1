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
                print("Slider changing to \(currentValue)")
        
                dispatch_async(dispatch_get_main_queue(),{
                    self.theta_label.text = "\(currentValue)"
                })
        
    }
    
 
    // To display changing Phi value on the app screen
    
    @IBAction func phiSliderValueChanged(sender: UISlider) {

                let currentValue = Int(sender.value)
                print("Slider changing to \(currentValue)")
        
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if status == .Authorized {
            self.myImageView.image = info[UIImagePickerControllerEditedImage] as? UIImage
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
        
        // The IP address in the URL below needs to be changed according to the web server details.
        /*
        let myUrl = NSURL(string: "http://192.168.199.125:8888/nicmpfromapp/http-post-example-script.php");
        let request = NSMutableURLRequest(URL:myUrl!);
        request.HTTPMethod = "POST";
        
        let param = [
            "firstName"  : "Sriram",
            "lastName"    : "Vepuri",
            "theta" : String(theta_label.text!),
            "phi": String(phi_label.text!)
        ]
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let imageData = UIImageJPEGRepresentation(myImageView.image!, 1)
        
        if(imageData==nil)  {
            print("imageData is NULL")
            return;
        } else {
            print("imageData has data")
            print(imageData?.length)
        }
        
        request.HTTPBody = createBodyWithParameters(param, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        print(timestamp)
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        //      Use these below parameters to increase the time interval to receive response from the web server
        //      sessionConfig.timeoutIntervalForRequest = 500.0;
        //      sessionConfig.timeoutIntervalForResource = 500.0;
        
        let session = NSURLSession(configuration: sessionConfig)
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            
            // You can print out response object
            print("******* response = \(response)")
            
            // Print out reponse body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("****** response data = \(responseString!)")
            
            self.response_label.text = responseString as? String
            print(self.response_label.text)
            
            dispatch_async(dispatch_get_main_queue(),{
                self.performSegueWithIdentifier("segueToResultsVC", sender: self)
            });
        });
        
        task.resume()*/
        let imageProcessor = ImageProcessor()
        imageProcessor.inputImage = myImageView.image
        self.performSegueWithIdentifier("segueToResultsVC", sender: imageProcessor.resultImage)
    }
    
    
    // This function is called to take the user to the next screen in the app, when the image processing result is sent by the web server.
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        print("prepare for segue")
        if (segue.identifier == "segueToResultsVC") {
            
            let svc = segue.destinationViewController as! ResultsVC;
            let image = sender as! UIImage
            svc.orinigalImage = image
            
        }
    }
    
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData {
        let body = NSMutableData();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        let filename = "location-image.jpg"
        let mimetype = "image/jpg"
        
        //        let filename = "user-profile.png"
        //        let mimetype = "image/png"
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        
        print("imageDataKey details ....")
        print(imageDataKey.length)
        
        body.appendData(imageDataKey)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    
        func generateBoundaryString() -> String {
            return "Boundary-\(NSUUID().UUIDString)"
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
            LatitudeGPS = String(format: "%.15f", manager.location!.coordinate.latitude)
            LongitudeGPS = String(format: "%.15f", manager.location!.coordinate.longitude)
            Lat_label.text = LatitudeGPS as String
            Long_label.text = LongitudeGPS as String
        }
    
//        func locationManagerDirection(manager: CLLocationManager, didUpdateHeading newHeading: [CLHeading]) {
//            print(newHeading.magneticHeading)
//        }
    
    
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

            let concatnatedValue = dir + " " + String(h)
            magLabel.text = concatnatedValue
            print(concatnatedValue)
        
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


