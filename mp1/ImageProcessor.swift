//
//  ImageProcessor.swift
//  mp1
//
//  Created by Yifan on 6/5/16.
//
//

import Foundation
import UIKit
import QuartzCore

class ImageProcessor
{
    var inputProject : ImageProject? {
        didSet {
            //threshold = i
            skyPoints = inputProject?.skyPoints
            nonSkyPoints = inputProject?.nonSkyPoints
            
            if inputProject?.originalImage != nil {
                getNewPixelsCount(colorFilter: useOnlyBlueColor)
            }
            
            if inputProject?.edittedImage == nil {
                processWithDefaultThershold()
            }
        }
    }
    
    /*
    var inputImage : UIImage? {
        didSet {
            if (inputImage != nil) {
                getNewPixelsCount(averageRGB)            }
        }
    }
    */
    
    var threshold : Double? {
        
        get {
            return inputProject?.threshold
        }
        set {
            if inputProject != nil {
                inputProject?.threshold = newValue
                inputProject?.isThresholdAutoDecided = false
                processImage(colorFilter: averageRGB)
            }
        }
    }
    
    /*
    var skyViewFactor : Double? {
        if (nonSkyPoints + skyPoints) == 0 {
            return nil
        } else {
            return (skyPoints / (skyPoints + nonSkyPoints))
        }
    }
     */
    
    func processWithDefaultThershold() {
        if inputProject?.autoThreshold == nil {
            
            inputProject?.autoThreshold = clusterRidlerAlgorithm(colorThreshold: Constant.clusterRidlerInitValue)
            
        }
        inputProject?.threshold = inputProject?.autoThreshold
        inputProject?.isThresholdAutoDecided = true
        processImage(colorFilter: averageRGB)
        
    }
    
    private func Otsus(start: Int, end: Int) {
        let newCount = histogramCounts[start..<end]
        let total = Double(newCount.reduce(0, +))
        var sumB  = 0.0
        var wB = 0.0
        var wF = 0.0
        var maximum = 0.0
        var sum1 = 0.0
        var mF  = 0.0
        
        for ii in start ..< end {
            wB = wB + Double(newCount[ii-start])
            wF = total - wB
            if (wB != 0 ) && (wF != 0) {
                sumB = sumB + Double(ii * histogramCounts[ii])
                mF = (sum1 - sumB) / wF
                
            }
            
        }
        
        
        
    }
    
    private struct Constant {
        static var clusterRidlerInitValue = 128.0
    }
    
    //private var edittedImage : UIImage?
    //private var combinedImage : UIImage?
    private var globalUpperThreshold : Double?
    private var globalLowerThreshold : Double?
    private var histogramCounts = [Int](repeating: 0, count: 257)
    private var radious: Int?
    
    private var skyPoints : Double?
    /*{
        get {
            return inputProject?.skyPoints
        }
        set {
            inputProject?.skyPoints = newValue
        }
    }*/
    private var nonSkyPoints : Double?
    /*
    {
        get {
            return inputProject?.nonSkyPoints
        }
        set {
            inputProject?.nonSkyPoints = newValue
        }
    }
     */
    
    private var filteredPixelsCount : [Double]?
    private var colorThreshold = 128.0
    
    //typealias selectedMethod = averageRGB
    //var selectedMethod = averageRGB
    
    private func clusterRidlerAlgorithm(colorThreshold : Double) -> Double {
        var brightAverage = AverageCalculator()
        var darkAverage = AverageCalculator()
        
        for colorValue in filteredPixelsCount! {
            if colorValue > colorThreshold {
                brightAverage.addValue(value: colorValue)
            } else {
                darkAverage.addValue(value: colorValue)
            }
        }
        
        let newThreshold = (brightAverage.result + darkAverage.result) / 2
        print("new threshold = \(newThreshold)")
        if newThreshold == colorThreshold {
            return newThreshold
        }
        
        return clusterRidlerAlgorithm(colorThreshold: newThreshold)
    }
    
    private struct AverageCalculator
    {
        var result = 0.0
        private var count = 0
        mutating func addValue(value: Double) {
            let doubleCount = Double(count)
            result = doubleCount / (doubleCount + 1) * result + value / (doubleCount + 1)
            count = count + 1
        }
    }
    
    private func getNewPixelsCount(colorFilter : (Double, Double, Double) -> Double) {
        
        if inputProject != nil {
            let inputCGImage     = inputProject!.originalImage!.cgImage
            let colorSpace       = CGColorSpaceCreateDeviceRGB()
            let width            = inputCGImage!.width
            let height           = inputCGImage!.height
            let bytesPerPixel    = 4
            let bitsPerComponent = 8
            let bytesPerRow      = bytesPerPixel * width
            let bitmapInfo       = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
            context?.draw(inputCGImage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)))
            
            //CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), inputCGImage)
            //draw(context)
            
            let uncasteddata = UnsafeRawPointer(context!.data)
            let pixelBuffer = uncasteddata?.assumingMemoryBound(to: UInt32.self)
            var currentPixel = pixelBuffer!
            //filteredPixelsCount = [Double](repeating: 0.0, count: width * height)
            
            radious = min(height, width)
            
            for  h in 0..<Int(height) {
                for  w in 0..<Int(width) {
                    let pixel = currentPixel.pointee
                    //let pixel = currentPixel
                    let brightness = colorFilter(Double(getRedComponent(color: pixel)) , Double(getBlueComponent(color:pixel)) , Double(getGreenComponent(color:pixel)) )
                    //filteredPixelsCount![h * width + w] = brightness
                    let xx = abs(h - height / 2)
                    let yy = abs(w - width / 2)
                    if (pow(Double(xx), 2) + pow(Double(yy), 2) < pow(Double(radious!), 2)) {
                        histogramCounts[Int(brightness) + 1] = histogramCounts[Int(brightness) + 1] + 1
                    }
                    currentPixel = currentPixel + 1
                }
            }
            print("Done calculating pixels count!")
        } else {
            filteredPixelsCount = nil
        }
    }
    
    private var convertRGBToGrayScale = { (red: Double, green: Double, blue: Double) -> Double in
        
        return red * 0.2126 + green * 0.7152 + blue * 0.0722
    }
    
    private var averageRGB = { (red: Double,  green: Double, blue: Double) -> Double  in
        
        return (red + green + blue) / 3
    }
    
    private var useOnlyBlueColor = { (red: Double,  green: Double, blue: Double) -> Double  in
        var correctedBlue = 255.0 * pow((blue / 255.0), 0.45)
        if correctedBlue > 255 {
            correctedBlue = 255
        }
        if correctedBlue < 0 {
            correctedBlue = 0;
        }
        return correctedBlue
    }
    
    private func initAllStatus() {
        
        //edittedImage = nil
        //combinedImage = nil
        skyPoints = 0.0
        nonSkyPoints = 0.0
    }
    
    private func processOriginalImage(colorFilter: (Double, Double, Double) -> Double) {
       // var start = CACurrentMediaTime()

        let inputCGImage     = inputProject!.originalImage!.cgImage
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage!.width
        let height           = inputCGImage!.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        
        context?.draw(inputCGImage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)))
        
        let uncasteddata = UnsafeMutableRawPointer(context!.data)
        let pixelBuffer = uncasteddata?.assumingMemoryBound(to: UInt32.self)
        var currentPixel = pixelBuffer!
        
        let blackColor = getColorFromRgba(red: 0, green: 0, blue: 0, alpha: 255)
        let whiteColor = getColorFromRgba(red: 255, green: 255, blue: 255, alpha: 255)
        
        //print("\(threshold!): loop: \(CACurrentMediaTime() - start)" )
        //start = CACurrentMediaTime()
        
        let localThreshold = threshold
        
        for  h in 0..<Int(height) {
            for  w in 0..<Int(width) {
                //let pixel = currentPixel.memory
                //let brightness = colorFilter(Double(getRedComponent(pixel)) , Double(getBlueComponent(pixel)) , Double(getGreenComponent(pixel)) )
                let brightness = filteredPixelsCount![h * width + w]
                
                if brightness > localThreshold! {
                    currentPixel.pointee = whiteColor
                    skyPoints = skyPoints! + 1
                } else {
                    currentPixel.pointee = blackColor
                    nonSkyPoints = nonSkyPoints! + 1
                }
                
                currentPixel = currentPixel + 1
            }
        }
        
        inputProject?.skyPoints = skyPoints
        inputProject?.nonSkyPoints = nonSkyPoints
        
        //print("\(threshold!): loop \(CACurrentMediaTime() - start)" )
        //start = CACurrentMediaTime()
        
        let outputCGImage = context!.makeImage()
        inputProject?.edittedImage = UIImage(cgImage: outputCGImage!, scale: inputProject!.originalImage!.scale, orientation: inputProject!.originalImage!.imageOrientation)
        
        //let end = CACurrentMediaTime()
        //print("\(threshold!): ending: \(end - start)" )
        
    }
    
    private func processImage(colorFilter: (Double, Double, Double) -> Double) {
        
        initAllStatus()
        if inputProject != nil {
            
            processOriginalImage(colorFilter: colorFilter)
            //mergeTwoImage()
        }
    }
    
    /*
    private func mergeTwoImage() {
        let height = CGImageGetHeight(inputImage!.CGImage)
        let width = CGImageGetWidth(inputImage!.CGImage)
        let imageRect = CGRectMake(0, 0, CGFloat(width), CGFloat(height))
        
        UIGraphicsBeginImageContextWithOptions(inputImage!.size, false, inputImage!.scale)
        let context = UIGraphicsGetCurrentContext()
        
        let flip = CGAffineTransformMakeScale(1.0, -1.0);
        let flipThenShift = CGAffineTransformTranslate(flip,0,CGFloat(-height));
        CGContextConcatCTM(context, flipThenShift);
        
        let transformedRect = CGRectApplyAffineTransform(imageRect, flipThenShift);
        
        CGContextDrawImage(context, transformedRect, inputImage!.CGImage)
        CGContextSetBlendMode(context, CGBlendMode.SourceAtop)
        CGContextSetAlpha(context, 0.5)
        CGContextDrawImage(context, transformedRect, edittedImage!.CGImage)
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //combinedImage = UIImage(CGImage: rotatedImage.CGImage!, scale: inputImage!.scale, orientation: inputImage!.imageOrientation)
        
    }
    */
    
    private func getRedComponent(color: UInt32) -> UInt8 {
        let color = UInt8(color & 0xFF)
        return color
    }
    
    private func getGreenComponent(color: UInt32) -> UInt8 {
        let color = UInt8((color >> 8) & 0xFF)
        return color
    }
    
    private func getBlueComponent(color: UInt32) -> UInt8 {
        let color = UInt8((color >> 16) & 0xFF)
        return color
    }
    
    private func getColorFromRgba(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> UInt32 {
        return UInt32(red) | (UInt32(green) << 8) | (UInt32(blue) << 16) | (UInt32(alpha) << 24)
    }
    
}




















