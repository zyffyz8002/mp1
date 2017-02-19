//
//  CheckLevelerViewController.swift
//  mp1
//
//  Created by Yifan on 7/14/16.
//
//

import UIKit
import AVFoundation

class CheckLevelerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    struct storyboardIdentifier {
        static let segueToResultVC = "Show Result"
    }

    fileprivate func addLeveler() {
        
        /*
        levelerViewController.levelerView.frame = levelerView.bounds
        levelerViewController.willMoveToParentViewController(self)
        levelerView.addSubview(levelerViewController.levelerView)
        addChildViewController(levelerViewController)
        levelerViewController.didMoveToParentViewController(self)
        */
        levelerViewController.view.frame = levelerView.bounds
        levelerView.addSubview(levelerViewController.view)
        //addChildViewController(levelerViewController)
    }
        
    @IBOutlet weak var LevelingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = GeneralConstant.APPName
        addLeveler()
        updateLocation()
        requestCamperaAutherization()
        MotionAndLocationManager.requestAutherization()
        // Do any additional setup after loading the view.
    }

    fileprivate func updateLeveler() {
        levelerViewController.startUpdateLeveler {
            [unowned self]
            (data, error) in
            if LevelerViewController.leveled(data) {
                OperationQueue.main.addOperation {
                    self.LevelingLabel.text = "Leveled!"
                    self.LevelingLabel.textColor = UIColor.green
                }
            } else {
                OperationQueue.main.addOperation {
                    self.LevelingLabel.text = "Leveling..."
                    self.LevelingLabel.textColor = UIColor.red
                }
            }
            self.view.setNeedsDisplay()     //?????
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLeveler()
        print("checker will appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        levelerViewController.stopUpdateLeveler()
        print("checker will disappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //levelerViewController.stopUpdateLeveler()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBOutlet weak var levelerView: UIView!
    
    fileprivate var levelerViewController = LevelerViewController(nibName: "LevelerViewController", bundle: nil)
    
    @IBOutlet weak var locationLabel: UILabel!
    
    fileprivate func updateLocation() {
        var latitudeText = "--"
        var longtitudeText = "--"
        if let latitude = MotionAndLocationManager.latitude {
            latitudeText = "\(latitude)"
        }
        
        if let longtitude = MotionAndLocationManager.longtitude {
            longtitudeText = "\(longtitude)"
        }
        locationLabel.text = latitudeText + ", " + longtitudeText
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        presentPickerWithOverlayView()
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
    
    fileprivate var picker = LevelerUIImagePickerController()
    fileprivate var imageProject = ImageProject()
    
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
    
    fileprivate func initCameraPicker() {
        picker.delegate = self
        
    }

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
            picker.cameraOverlayView?.subviews.first?.removeFromSuperview()
            picker.addLevelerViewToOverlayView()
        }
    }
    
    @objc func changeToPhotoCatureOverlay(_ picker : UIImagePickerController) {
        if let cameraOverlayView = self.picker.cameraOverlayView as? CameraOverlayView {
            let pickerFrame = self.picker.view.frame
            cameraOverlayView.frame = pickerFrame
            cameraOverlayView.screenMode = .photoCaptureScreen
            self.picker.cameraOverlayView?.subviews.first?.removeFromSuperview()
            self.picker.addLevelerViewToOverlayView()
        }
        //let levelerPicker = picker as? LevelerUIImagePickerController
        self.picker.levelerViewController.startUpdateLeveler (nil)
    }
    
    
    fileprivate func requestCamperaAutherization() {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) {
            granted in
            if (granted) {
                print("User allowed camera")
            }  else {
                print("User denied camera")
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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

















































