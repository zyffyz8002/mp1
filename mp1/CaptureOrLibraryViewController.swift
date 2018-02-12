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
    
    @IBAction func capturePhoto(_ sender: UIButton) {

        //presentPickerWithOverlayView()
    }
    
    fileprivate var picker = LevelerUIImagePickerController()

    
    fileprivate func initCameraPicker() {
        picker.delegate = self

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        dismiss(animated: true, completion: nil)
        switch picker.sourceType {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            if status == .authorized {
                if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    imageProject.originalImage = UIImage.createSquareImage(fromImage: originalImage)
                    performSegue(withIdentifier: storyboardIdentifier.segueToResultVC, sender: imageProject)
                }
            }
        case .photoLibrary:
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imageProject.originalImage  = UIImage.normalizeImage(image)
            }
            
        default:
            break
        }
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
    
    fileprivate var imageProject = ImageProject()

    @objc func changeToConfirmScreenOverlay() {
        imageProject.updateGeoInfo()
        picker.levelerViewController.stopUpdateLeveler()
        //picker.stopUpdateLeveler()
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
        //let levelerPicker = picker as? LevelerUIImagePickerController
        self.picker.levelerViewController.startUpdateLeveler(nil)
    }
    
    fileprivate func addOverlayViewObserver() {
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
    }
    
    fileprivate func presentPicker() {
        initCameraPicker()
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
    
    fileprivate func presentPickerWithOverlayView() {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == .authorized {
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
                picker.sourceType = .camera
                picker.cameraCaptureMode = .photo
                addOverlayViewObserver()
                presentPicker()
            }
        }
        else {
            let noCameraPermissionAlert = UIAlertController(title: "Camera Permission", message: "No permission to camera, please go to setting -> privacy -> camera", preferredStyle: .alert)
            noCameraPermissionAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = GeneralConstant.APPName
        askForCamperaPermission()
        
                // Do any additional setup after loading the view.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == storyboardIdentifier.segueToResultVC {
            if let destinationVC = segue.destination as? ResultsVC {
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
    
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}

struct PhotoScreenBounds {
    static let captureScreenUpperBound : CGFloat = 40
    static let captureScreenLowerBound : CGFloat = 100
    static let confirmScreenLowerBound : CGFloat = 70
    static let confirmScreenUpperBound : CGFloat = 70
}




extension UIImage {
    
    class func createSquareImage(fromImage originalImage: UIImage) -> UIImage {
        let shortSide = originalImage.size.width < originalImage.size.height ? originalImage.size.width : originalImage.size.height
        let longSide = originalImage.size.width >= originalImage.size.height ? originalImage.size.width : originalImage.size.height
        let clipped = (longSide - shortSide) / 2
        let rect = CGRect(x: 0, y: clipped, width: shortSide, height: shortSide)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, originalImage.scale)
        originalImage.draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage!
    }
    
    class func normalizeImage(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: CGPoint(x:0, y:0), size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage!
    }
}

