//
//  ResultsVC.swift
//  mp1
//
//  Created by Sriram Vepuri on 12/31/15.
//
//

import UIKit

class ResultsVC: UIViewController {

    
    //@IBOutlet var myWebView: UIWebView!

    @IBOutlet weak var resultImageView: UIImageView!
    
    var orinigalImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()


        self.navigationItem.title = "Result"
        resultImageView.image = orinigalImage
        
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
