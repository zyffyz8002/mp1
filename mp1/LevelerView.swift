//
//  LeverlerView.swift
//  mp1
//
//  Created by Yifan on 6/8/16.
//
//

import UIKit

@IBDesignable

class LevelerView: UIView {
    

    
    var offset = CGPoint(x: 0, y:0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private func drawCircle(center: CGPoint, radius: CGFloat, fill: Bool) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.addArcWithCenter(center, radius: radius, startAngle: 0, endAngle: CGFloat(M_PI*2), clockwise: true)
        path.lineWidth = CGFloat(1.0)
        if fill {
            path.fill()
        }
        
        return path
    }

    override func drawRect(rect: CGRect) {
        UIColor.blueColor().set()
        drawCircle(CGPoint(x: bounds.width/2, y: bounds.height/2), radius: LevelerParameters.Radius, fill: false).stroke()
        drawCircle(CGPoint(x: bounds.width/2 + offset.x, y: bounds.height/2 + offset.y), radius: CGFloat(2), fill: true).stroke()
     
    }

}
