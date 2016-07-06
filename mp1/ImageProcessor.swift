//
//  ImageProcessor.swift
//  mp1
//
//  Created by Yifan on 6/5/16.
//
//

import Foundation
import UIKit

class ImageProcessor
{
    var inputProject : ImageProject? {
        didSet {
            if inputProject?.originalImage != nil {
                getNewPixelsCount(averageRGB)
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
    
    var threshold : Double?  {
        get {
            return inputProject?.threshold
        }
        set {
            if inputProject != nil {
                inputProject?.threshold = newValue
                inputProject?.isThresholdAutoDecided = false
                processImage(averageRGB)
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
            inputProject?.autoThreshold = clusterRidlerAlgorithm(Constant.clusterRidlerInitValue)
            
        }
        inputProject?.threshold = inputProject?.autoThreshold
        inputProject?.isThresholdAutoDecided = true
        processImage(averageRGB)
        
    }
    
    private struct Constant {
        static var clusterRidlerInitValue = 128.0
    }
    
    //private var edittedImage : UIImage?
    //private var combinedImage : UIImage?
    private var skyPoints : Double? {
        get {
            return inputProject?.skyPoints
        }
        set {
            inputProject?.skyPoints = newValue
        }
    }
    private var nonSkyPoints : Double? {
        get {
            return inputProject?.nonSkyPoints
        }
        set {
            inputProject?.nonSkyPoints = newValue
        }
    }
    
    
    private var filteredPixelsCount : [Double]?
    private var colorThreshold = 128.0
    //typealias selectedMethod = averageRGB
    //var selectedMethod = averageRGB
    
    private func clusterRidlerAlgorithm(colorThreshold : Double) -> Double {
        var brightAverage = AverageCalculator()
        var darkAverage = AverageCalculator()
        
        for colorValue in filteredPixelsCount! {
            if colorValue > colorThreshold {
                brightAverage.addValue(colorValue)
            } else {
                darkAverage.addValue(colorValue)
            }
        }
        
        let newThreshold = (brightAverage.result + darkAverage.result) / 2
        print("new threshold = \(newThreshold)")
        if newThreshold == colorThreshold {
            return newThreshold
        }
        
        return clusterRidlerAlgorithm(newThreshold)
    }
    
    private struct AverageCalculator
    {
        var result = 0.0
        private var count = 0
        private mutating func addValue(value: Double) {
            let doubleCount = Double(count)
            result = doubleCount / (doubleCount + 1) * result + value / (doubleCount + 1)
            count = count + 1
        }
    }
    
    private func getNewPixelsCount(colorFilter : (Double, Double, Double) -> Double) {
        
        if inputProject != nil {
            let inputCGImage     = inputProject!.originalImage!.CGImage
            let colorSpace       = CGColorSpaceCreateDeviceRGB()
            let width            = CGImageGetWidth(inputCGImage)
            let height           = CGImageGetHeight(inputCGImage)
            let bytesPerPixel    = 4
            let bitsPerComponent = 8
            let bytesPerRow      = bytesPerPixel * width
            let bitmapInfo       = CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
            let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
            CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), inputCGImage)
            
            let pixelBuffer = UnsafeMutablePointer<UInt32>(CGBitmapContextGetData(context))
            var currentPixel = pixelBuffer
            filteredPixelsCount = [Double](count: width * height, repeatedValue: 0.0)
            
            for  h in 0..<Int(height) {
                for  w in 0..<Int(width) {
                    let pixel = currentPixel.memory
                    let brightness = colorFilter(Double(getRedComponent(pixel)) , Double(getBlueComponent(pixel)) , Double(getGreenComponent(pixel)) )
                    filteredPixelsCount![h * width + w] = brightness
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
        
        return blue
    }
    
    private func initAllStatus() {
        
        //edittedImage = nil
        //combinedImage = nil
        skyPoints = 0.0
        nonSkyPoints = 0.0
    }
    
    private func processOriginalImage(colorFilter: (Double, Double, Double) -> Double) {
        
        let inputCGImage     = inputProject!.originalImage!.CGImage
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = CGImageGetWidth(inputCGImage)
        let height           = CGImageGetHeight(inputCGImage)
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), inputCGImage)
        
        let pixelBuffer = UnsafeMutablePointer<UInt32>(CGBitmapContextGetData(context))
        var currentPixel = pixelBuffer
        
        let blackColor = getColorFromRgba(red: 0, green: 0, blue: 0, alpha: 255)
        let whiteColor = getColorFromRgba(red: 255, green: 255, blue: 255, alpha: 255)
        
        for  _ in 0..<Int(height) {
            for  _ in 0..<Int(width) {
                let pixel = currentPixel.memory
                let brightness = colorFilter(Double(getRedComponent(pixel)) , Double(getBlueComponent(pixel)) , Double(getGreenComponent(pixel)) )
                
                if brightness > threshold {
                    currentPixel.memory = whiteColor
                    skyPoints = skyPoints! + 1
                } else {
                    currentPixel.memory = blackColor
                    nonSkyPoints = nonSkyPoints! + 1
                }
                
                currentPixel = currentPixel + 1
            }
        }
        
        let outputCGImage = CGBitmapContextCreateImage(context)
        inputProject?.edittedImage = UIImage(CGImage: outputCGImage!, scale: inputProject!.originalImage!.scale, orientation: inputProject!.originalImage!.imageOrientation)
    }
    
    private func processImage(colorFilter: (Double, Double, Double) -> Double) {
        
        initAllStatus()
        if inputProject != nil {
            
            processOriginalImage(colorFilter)
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
    
    private func getColorFromRgba(red red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> UInt32 {
        return UInt32(red) | (UInt32(green) << 8) | (UInt32(blue) << 16) | (UInt32(alpha) << 24)
    }
    
}




















