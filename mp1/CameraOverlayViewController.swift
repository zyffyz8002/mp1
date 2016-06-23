//
//  CameraOverlayViewController.swift
//  mp1
//
//  Created by Yifan on 6/7/16.
//
//

import UIKit
import CoreMotion

class CameraOverlayViewController: UIViewController {
 
    private func addLevelerView() {
        let levelerView = LevelerView()
        levelerView.frame = CGRect(origin: CGPoint(x: 100, y: 0), size: CGSize(width: LevelerParameters.MaxRange, height: LevelerParameters.MaxRange))
        self.view.addSubview(levelerView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addLevelerView()
        // Do any additional setup after loading the view.
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
