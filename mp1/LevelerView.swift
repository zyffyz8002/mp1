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
    

    var lineWidth = CGFloat(1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
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
    
    fileprivate var compassRadius = CGFloat(LevelerParameters.maxRange / 2)
        
    var shouldDrawBackground = false
    
    //var scale = CGFloat(1) {
    //    didSet {
    //        setNeedsDisplay()
    //    }
    //}
    
    fileprivate func drawCircle(_ center: CGPoint, radius: CGFloat, fill: Bool) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(M_PI*2), clockwise: true)
        path.lineWidth = lineWidth
        if fill {
            path.fill()
        }
        
        return path
    }
    
    fileprivate func drawALine(pointA: CGPoint, pointB: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: pointA)
        path.addLine(to: pointB)
        path.lineWidth = lineWidth
        
        return path
    }
    
    fileprivate func rad(_ direction : CGFloat) -> CGFloat {
        return (direction / 180 * CGFloat(M_PI))
    }
    
    fileprivate func drawBackground() -> UIBezierPath {
        let path = UIBezierPath()
        
        
        path.move(to: bounds.origin)
        path.addLine(to: CGPoint(x: 0, y: bounds.height))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        path.addLine(to: CGPoint(x: bounds.width, y: 0))
        path.close()
        path.fill()
        
        return path
    }
    
    fileprivate var boundsCenter : CGPoint {
        get {
            return CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        }
    }

    override func draw(_ rect: CGRect) {
        if shouldDrawBackground {
            UIColor.black.set()
            drawBackground().stroke()
        }
        UIColor.blue.set()
        backgroundColor = UIColor.clear
        
        let scale = min(bounds.height, bounds.width) * 0.45 /  compassRadius
        
        drawCircle(
            boundsCenter,
            radius: compassRadius * scale, fill: false
        ).stroke()
        
        drawCircle(
            boundsCenter,
            radius: LevelerParameters.thresholdRadius * scale, fill: false
        ).stroke()
        
        
        drawCircle(
            CGPoint(x: bounds.width/2 + offset.x * scale, y: bounds.height/2 + offset.y * scale),
            radius: LevelerParameters.pointRadius * scale, fill: true
        ).stroke()
        
        
        let markerYStart = bounds.height / 2 - compassRadius * scale
        drawALine(
            pointA: CGPoint(x:bounds.width / 2, y: markerYStart ),
            pointB: CGPoint(x:bounds.width / 2, y: markerYStart + LevelerParameters.northMakerLength * pow(scale, 0.5))
        ).stroke()
        
        drawALine(
            pointA: CGPoint(x:bounds.width / 2, y: bounds.height / 2),
            pointB: CGPoint(
                x: bounds.width/2 + sin(-rad(direction)) * compassRadius * scale,
                y: bounds.height/2 - cos(-rad(direction)) * compassRadius * scale
            )
        ).stroke()
    }
    
    
    
}

struct LevelerParameters {
    
    static let sensitivity : CGFloat = 35 / 1.5
    static let updateInterval : Double = 0.1
    
    
    static let maxRange : CGFloat = 70
    static let thresholdRadius : CGFloat = 35 / 1.5 * 0.15
    static let northMakerLength : CGFloat = 10
    static let pointRadius : CGFloat = 1
}



























