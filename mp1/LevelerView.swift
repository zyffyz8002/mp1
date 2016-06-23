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
    

    var lineWidth = CGFloat(1.0)
    
    var offset = CGPoint(x: 0, y:0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var direction = CGFloat(0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var shouldDrawBackground = false
    
    private func drawCircle(center: CGPoint, radius: CGFloat, fill: Bool) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.addArcWithCenter(center, radius: radius, startAngle: 0, endAngle: CGFloat(M_PI*2), clockwise: true)
        path.lineWidth = lineWidth
        if fill {
            path.fill()
        }
        
        return path
    }
    
    private func drawALine(pointA pointA: CGPoint, pointB: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(pointA)
        path.addLineToPoint(pointB)
        path.lineWidth = lineWidth
        
        return path
    }
    
    private func rad(direction : CGFloat) -> CGFloat {
        return (direction / 180 * CGFloat(M_PI))
    }
    
    private func drawBackground() -> UIBezierPath {
        let path = UIBezierPath()
        
        path.moveToPoint(bounds.origin)
        path.addLineToPoint(CGPoint(x: 0, y: bounds.height))
        path.addLineToPoint(CGPoint(x: bounds.width, y: bounds.height))
        path.addLineToPoint(CGPoint(x: bounds.width, y: 0))
        path.closePath()
        path.fill()
        
        return path
    }

    override func drawRect(rect: CGRect) {
        if shouldDrawBackground {
            UIColor.blackColor().set()
            drawBackground().stroke()
        }
        UIColor.blueColor().set()
        drawCircle(CGPoint(x: bounds.width/2, y: bounds.height/2), radius: LevelerParameters.Radius, fill: false).stroke()
        drawCircle(CGPoint(x: bounds.width/2 + offset.x, y: bounds.height/2 + offset.y), radius: CGFloat(2), fill: true).stroke()
        drawALine(pointA: CGPoint(x:bounds.width / 2, y: CGFloat(0)), pointB: CGPoint(x:bounds.width / 2, y: CGFloat(10))).stroke()
        drawALine(pointA: CGPoint(x:bounds.width / 2, y: bounds.height / 2), pointB: CGPoint(x:bounds.width/2 + sin(-rad(direction)) * LevelerParameters.MaxRange , y: bounds.height/2 - cos(-rad(direction)) * LevelerParameters.MaxRange / 2 )).stroke()
    }

}
