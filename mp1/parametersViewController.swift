//
//  parametersViewController.swift
//  mp1
//
//  Created by Yifan on 7/6/16.
//
//

import UIKit

class parametersViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate
{

    struct storyboardIdentifier  {
        static let segueToResultVC  = "Show Result"
    }
    
    @IBOutlet weak var longtitudeText: UITextField!
    @IBOutlet weak var headingText: UITextField!
    @IBOutlet weak var latitudeText: UITextField!
    @IBOutlet weak var levelerDxText: UITextField!
    @IBOutlet weak var levelerDyText: UITextField!
    
    @IBAction func choosePhotoFromLibrary(sender: UIButton) {
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }
    
    private let picker = UIImagePickerController()
    private let imageProject = ImageProject()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        longtitudeText.delegate = self
        headingText.delegate = self
        latitudeText.delegate = self
        levelerDxText.delegate = self
        levelerDyText.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        dismissViewControllerAnimated(true, completion: nil)
        switch picker.sourceType {
        case .PhotoLibrary:
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imageProject.originalImage = UIImage.createSquareImage(fromImage: UIImage.normalizeImage(image))
                imageProject.longtidude = (longtitudeText.text == nil ? nil : Double(longtitudeText.text!))
                imageProject.latitude = (latitudeText.text == nil ? nil : Double(latitudeText.text!))
                imageProject.heading = (headingText.text == nil ? nil : Double(headingText.text!))
                let doubledx = levelerDxText.text==nil ? nil : Double(levelerDxText.text!)
                let doubledy = levelerDyText.text==nil ? nil : Double(levelerDyText.text!)
                
                imageProject.leveler = (doubledx == nil || doubledy ==  nil ? nil : LevelInformation(x: CGFloat(doubledx!), y: CGFloat(doubledy!)))
                performSegueWithIdentifier(storyboardIdentifier.segueToResultVC, sender: imageProject)
            }
            
        default:
            break
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == storyboardIdentifier.segueToResultVC {
            if let destinationVC = segue.destinationViewController as? ResultsVC {
                if let imageProject = sender as? ImageProject {
                    destinationVC.imageProject = imageProject
                }
            }
        }
    }
}
