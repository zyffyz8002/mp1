//
//  parametersViewController.swift
//  mp1
//
//  Created by Yifan on 7/6/16.
//
//

import UIKit

class ParametersViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate
{

    struct storyboardIdentifier  {
        static let segueToResultVC  = "Show Result"
    }
    
    @IBOutlet weak var longtitudeText: UITextField!
    @IBOutlet weak var headingText: UITextField!
    @IBOutlet weak var latitudeText: UITextField!
    @IBOutlet weak var levelerDxText: UITextField!
    @IBOutlet weak var levelerDyText: UITextField!
    
    @IBAction func choosePhotoFromLibrary(_ sender: UIButton) {
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    fileprivate let picker = UIImagePickerController()
    fileprivate let imageProject = ImageProject()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        longtitudeText.delegate = self
        headingText.delegate = self
        latitudeText.delegate = self
        levelerDxText.delegate = self
        levelerDyText.delegate = self
        navigationItem.title = GeneralConstant.APPName
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        dismiss(animated: true, completion: nil)
        switch picker.sourceType {
        case .photoLibrary:
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imageProject.originalImage = UIImage.createSquareImage(fromImage: UIImage.normalizeImage(image))
                imageProject.longtidude = (longtitudeText.text == nil ? nil : Double(longtitudeText.text!))
                imageProject.latitude = (latitudeText.text == nil ? nil : Double(latitudeText.text!))
                imageProject.heading = (headingText.text == nil ? nil : Double(headingText.text!))
                let doubledx = levelerDxText.text==nil ? nil : Double(levelerDxText.text!)
                let doubledy = levelerDyText.text==nil ? nil : Double(levelerDyText.text!)
                
                imageProject.leveler = (doubledx == nil || doubledy ==  nil ? nil : LevelInformation(x: CGFloat(doubledx!), y: CGFloat(doubledy!)))
                performSegue(withIdentifier: storyboardIdentifier.segueToResultVC, sender: imageProject)
            }
            
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == storyboardIdentifier.segueToResultVC {
            if let destinationVC = segue.destination as? ResultsVC {
                if let imageProject = sender as? ImageProject {
                    destinationVC.imageProject = imageProject
                }
            }
        }
    }
}
