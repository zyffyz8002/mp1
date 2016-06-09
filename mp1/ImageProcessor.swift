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
    var inputImage : UIImage? {
        didSet {
            if (inputImage != nil) {
            processImage()
            }
        }
    }
    
    var threshold  = 128.0 {
        didSet {
            if (inputImage != nil) {
            processImage()
            }
        }
    }
    
    private var edittedImage : UIImage?
    private var combinedImage : UIImage?
    private var skyPoints = 0.0
    private var nonSkyPoints = 0.0
    
    var resultImage : UIImage? {
        get {
            return edittedImage
        }
    }
    
    var overlayImage : UIImage? {
        get {
            return combinedImage
        }
    }
    
    private func initAllStatus() {
        edittedImage = nil
        combinedImage = nil
        skyPoints = 0.0
        nonSkyPoints = 0.0
    }
    
    var skyViewFactor : Double? {
        if nonSkyPoints == 0 {
            return nil
        } else {
            return (skyPoints / (skyPoints + nonSkyPoints))
        }
    }
    
    func processImage()
    {
        initAllStatus()
        if inputImage != nil {
            let inputCGImage     = inputImage!.CGImage
            let colorSpace       = CGColorSpaceCreateDeviceRGB()
            let width            = CGImageGetWidth(inputCGImage)
            let height           = CGImageGetHeight(inputCGImage)
            let bytesPerPixel    = 4
            let bitsPerComponent = 8
            let bytesPerRow      = bytesPerPixel * width
           // let bitmapByteCount  = bytesPerRow * height
            let bitmapInfo       = CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
            //let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
            
            
          //  var bitmapData:UnsafeMutablePointer<Void> = malloc(bitmapByteCount)
            
            let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
            //let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)!
            CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), inputCGImage)
            
            
            //let pixelBuffer = UnsafeMutablePointer<UInt32>(CGBitmapContextGetData(context))
            let pixelBuffer = UnsafeMutablePointer<UInt32>(CGBitmapContextGetData(context))
            var currentPixel = pixelBuffer
            
            //var currentPixel = pixelBuffer
            //var base, offset: Int
            
            let blackColor = getColorFromRgba(red: 0, green: 0, blue: 0, alpha: 255)
            let whiteColor = getColorFromRgba(red: 255, green: 255, blue: 255, alpha: 255)
            
            for  _ in 0..<Int(height) {
                for  _ in 0..<Int(width) {
                    let pixel = currentPixel.memory
                    let brightness = (Double(getRedComponent(pixel)) + Double(getBlueComponent(pixel)) + Double(getGreenComponent(pixel))) / 3.0
                    
                    if brightness > threshold {
                        currentPixel.memory = whiteColor
                        skyPoints = skyPoints + 1
                    } else {
                        currentPixel.memory = blackColor
                        nonSkyPoints = nonSkyPoints + 1
                    }
                    
                    currentPixel = currentPixel + 1
                }
            }
            

            let outputCGImage = CGBitmapContextCreateImage(context)
            edittedImage = UIImage(CGImage: outputCGImage!, scale: inputImage!.scale, orientation: inputImage!.imageOrientation)
            mergeTwoImage()
        }
    }
    
    private func mergeTwoImage() {
        if inputImage != nil {
            let imageRect = CGRect(origin: CGPointZero, size: inputImage!.size)
            //let height = CGRectGetHeight(imageRect)
            //let width = CGRectGetWidth(imageRect)
            
            UIGraphicsBeginImageContextWithOptions(inputImage!.size, false, inputImage!.scale)
            let context = UIGraphicsGetCurrentContext()
            CGContextDrawImage(context, imageRect, inputImage!.CGImage)
            CGContextSetBlendMode(context, CGBlendMode.SourceAtop)
            CGContextSetAlpha(context, 0.5)
            CGContextDrawImage(context, imageRect, edittedImage!.CGImage)
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            combinedImage = UIImage(CGImage: rotatedImage.CGImage!, scale: 1, orientation: UIImageOrientation(rawValue: -90)!)
        }
    }
    
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




















