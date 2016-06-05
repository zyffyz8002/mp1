//
//  ResultsVC.swift
//  mp1
//
//  Created by Sriram Vepuri on 12/31/15.
//
//

import UIKit

class ResultsVC: UIViewController {

    @IBOutlet var resultLabel: UILabel!
    
    @IBOutlet var myWebView: UIWebView!
    
    var toPass:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myWebView.loadHTMLString(toPass, baseURL: nil)
        
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
