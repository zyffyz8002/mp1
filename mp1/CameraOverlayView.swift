//
//  CameraOverlayView.swift
//  mp1
//
//  Created by Yifan on 6/7/16.
//
//

import UIKit

class CameraOverlayView: UIView {
    
    
    private func drawARect(path: UIBezierPath, startPoint: CGPoint, width: CGFloat, height: CGFloat) {
        path.moveToPoint(startPoint)
        path.addLineToPoint(CGPoint(x: startPoint.x + width, y: startPoint.y))
        path.addLineToPoint(CGPoint(x: startPoint.x + width, y: startPoint.y + height))
        path.addLineToPoint(CGPoint(x: startPoint.x , y: startPoint.y + height))
        path.closePath()
        path.fill()
    }
    
    private func drawOverlay() -> UIBezierPath
    {
        let path = UIBezierPath()
        if screenMode != nil {
            let shortSide = bounds.width > bounds.height ? bounds.height: bounds.width
            let longSide = bounds.width <= bounds.height ? bounds.height: bounds.width
            var clippedLength : CGFloat = (longSide - shortSide - PhotoScreenBounds.captureScreenLowerBound - PhotoScreenBounds.captureScreenUpperBound) / 2
            var UpperBound = PhotoScreenBounds.captureScreenUpperBound
            
            let recWidth = shortSide
            var lowerRecHeight = clippedLength
            switch screenMode! {
            case .photoCaptureScreen:
                lowerRecHeight = clippedLength
                UpperBound = PhotoScreenBounds.captureScreenUpperBound
            case .photoConfirmScreen:
                clippedLength = clippedLength + PhotoScreenBounds.confirmScreenLowerBound / 2
                lowerRecHeight = clippedLength + PhotoScreenBounds.captureScreenLowerBound - PhotoScreenBounds.confirmScreenLowerBound
                UpperBound = PhotoScreenBounds.confirmScreenUpperBound
            }
            let offset = UpperBound + clippedLength + shortSide
            drawARect(path, startPoint: CGPoint(x: 0, y: UpperBound), width: recWidth, height: clippedLength)
            drawARect(path, startPoint: CGPoint(x: 0, y: offset), width: recWidth, height: lowerRecHeight)
        }
        return path
    }
    
    enum ScreenMode {
        case photoCaptureScreen
        case photoConfirmScreen
    }
    
    override func drawRect(rect: CGRect) {
        UIColor.blackColor().set()
        drawOverlay().stroke()
    }
    
    var screenMode : ScreenMode? {
        didSet {
            setNeedsDisplay()
        }
    }
}
