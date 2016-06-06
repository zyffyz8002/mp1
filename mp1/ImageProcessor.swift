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
    private var skyPoints = 0.0
    private var nonSkyPoints = 0.0
    var resultImage : UIImage? {
        get {
            return edittedImage
        }
    }
    
    private func initAllStatus() {
        edittedImage = nil
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
            
           /*
            var red, green, blue:UInt8
            var base, offset:Int
            
            for y in 0...(height - 1) {
                
                base = y * height * 4
                for x in 0...(width - 1) {
                    
                    offset = base + x * 4
                    
                    red   = pixelBuffer[offset + 1]
                    green = pixelBuffer[offset + 2]
                    blue  = pixelBuffer[offset + 3]
                    
                    let brightness = (Double(red) + Double(green) + Double(blue))/3
                    if brightness > threshold {
                       // currentPixel.memory = getColorFromRgba(red: 255, green: 255, blue: 255, alpha: 255)
                        skyPoints = skyPoints + 1
                    } else {
                       // currentPixel.memory = getColorFromRgba(red: 0, green: 0, blue: 0, alpha: 255)
                        nonSkyPoints = nonSkyPoints + 1
                    }
                }
            }*/
           /*
            */
            var outputCGImage = CGBitmapContextCreateImage(context)
            edittedImage = UIImage(CGImage: outputCGImage!, scale: inputImage!.scale, orientation: inputImage!.imageOrientation)
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




















