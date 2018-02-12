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
            skyPoints = (inputProject?.skyPoints)
            nonSkyPoints = (inputProject?.nonSkyPoints)
            
            if (inputProject!.edittedImage) == nil {
                getNewPixelsCount(colorFilter: useOnlyBlueColor)
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
                //processImage(colorFilter: averageRGB)
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
    
    private var globalLowerThreshold: Int = 0
    private var globalHigherThrehold: Int = 0
    private var localLowerThreshold: Double?
    private var localHigherThreshold: Double?
    private var height : Int?
    private var width : Int?
    
    func processWithDefaultThershold() {
        if inputProject?.autoThreshold == nil {
            
            (globalLowerThreshold, globalHigherThrehold) = GetTwoGlobalThresholds()
            inputProject?.autoThreshold = Double((globalLowerThreshold + globalHigherThrehold) / 2 )
            
            setInitialClassification()
            classifyMixedPixels()
            convertPixelMapBackToImage()
            
            //clusterRidlerAlgorithm(colorThreshold: Constant.clusterRidlerInitValue)
        }
        inputProject?.threshold = inputProject?.autoThreshold
        inputProject?.isThresholdAutoDecided = true
        //processImage(colorFilter: averageRGB)
    }
    
    private func GetTwoGlobalThresholds() -> (globalLowerThreshold : Int, globalHigherThreshold : Int) {
        
        let midThrehold = otsus(start: 0, end: 256)
        return(otsus(start: 0, end: midThrehold), otsus(start: midThrehold, end: 256))
    }
    
    private func setInitialClassification() {
        
        var count = 0
        nonSkyPoints = 0
        skyPoints = 0
        
        finalImageArray = [Int](repeating: -1, count: width! * height!)
        nonClassifiedCount = width! * height! + 10
        
        for h in 0..<height! {
            for w in 0..<width! {
        
                if pow(Double(h)-Double(height!)/2.0, 2) + pow(Double(w)-Double(width!)/2.0, 2) >= pow(Double(radious!), 2) {
                    finalImageArray[count] = 0
                    blueChannel[count] = 0
                    nonClassifiedCount = nonClassifiedCount - 1
                } else {
                    
                    if (blueChannel[count] < globalLowerThreshold) {
                        finalImageArray[count] = 0
                        nonClassifiedCount = nonClassifiedCount - 1
                        nonSkyPoints = nonSkyPoints! + 1
                    }
                    
                    if (blueChannel[count] > globalHigherThrehold) {
                        finalImageArray[count] = 255
                        nonClassifiedCount = nonClassifiedCount - 1
                        skyPoints = skyPoints! + 1
                    }
                }
                count = count + 1
            }
        }
    }
    
    private var nonClassifiedCount = 0
    
    private func imageFromPixelValues(pixelValues: [UInt32]?, width: Int, height: Int) ->  CGImage?
    {
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        let unsafeData = UnsafeMutableRawPointer(mutating: pixelValues)
        if let imageContext = CGContext(data: unsafeData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil) {
            let cgImage = imageContext.makeImage()
            
            return cgImage
        } else {
            return nil
        }
 
       /* var imageRef: CGImage?
        if let pixelValues = pixelValues
        {
            let bitsPerComponent = 8
            let bytesPerPixel = 4
            let bitsPerPixel = bytesPerPixel * bitsPerComponent
            let bytesPerRow = bytesPerPixel * width
            let totalBytes = height * bytesPerRow
            let releaseData: CGDataProviderReleaseDataCallback = {
                (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            }
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
                .union([])
            if let providerRef = CGDataProvider(dataInfo: nil, data: pixelValues, size: totalBytes, releaseData: releaseData) {
                
                let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
                imageRef = CGImage(width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bitsPerPixel: bitsPerPixel,
                                   bytesPerRow: bytesPerRow,
                                   space: colorSpaceRef,
                                   bitmapInfo: bitmapInfo,
                                   provider: providerRef,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: CGColorRenderingIntent.defaultIntent)
            }
        }
        
        return imageRef*/
        //return cgImage
    }
    
    var searched:[Bool]?
    var stackToSearch:[Int]?
    var positions : [Int]?
    var holeCounts = 0
    var classifiedMixedPixelCount = 0
    
    private func classifyMixedPixels() {
        var count = width!
        var positionSize : Int = 0
        var skyCounts : Int = 0
        var treeCounts : Int = 0
        var minSky : Int = 0
        var maxTree : Int = 0
        var localTh : Int = 0
        
        func LinearScale(_ value: Int, _ lowerBound: Int, _ upperBound: Int) -> Double {
            
            return Double(value - lowerBound) / Double(upperBound - lowerBound) * 255
        }
        
        for w in 0..<width! {
            finalImageArray[w] = 0
            blueChannel[w] = 0
            finalImageArray[(height!-1) * width!  + w] = 0
            blueChannel[(height!-1) * width!  + w] = 0
        }
        
        for h in 0..<height! {
            finalImageArray[h * width!] = 0
            blueChannel[h * width!] = 0
            finalImageArray[h * width! + width! - 1 ] = 0
            blueChannel[h * width! + width! - 1 ] = 0
        }
        
        if inputProject != nil {
            
            stackToSearch = [Int](repeating: 0, count: min(width!*height!, nonClassifiedCount * 4))
            positions = [Int](repeating: -1, count: nonClassifiedCount)
            searched = [Bool](repeating: false, count: width! * height!)
            holeCounts = 0
            
            for h in 1..<height! - 1 {
                for w in 1..<width! - 1 {
                    
                    count = w + h * width!
                    if (finalImageArray[count] == -1) {
                        (positionSize, treeCounts, skyCounts, minSky, maxTree) = getTheHolePixelsCounts(pixelCount: count)
                        if (treeCounts > 3 * skyCounts) {
                            localTh = Int(maxTree + (minSky - maxTree) * 2 / 3)
                        } else {
                            localTh = Int(maxTree + (minSky - maxTree) / 3)
                        }
                        
                        for i in 0..<positionSize {
                            let index = positions![i]
                            if (treeCounts > 3 * skyCounts) {
                                if (blueChannel[index] > localTh) {
                                    finalImageArray[index] = 255
                                    skyPoints = skyPoints! + 1
                                } else {
                                    let currentPixelWeight = LinearScale(blueChannel[index], maxTree, localTh)
                                    finalImageArray[index] = Int(currentPixelWeight)
                                    nonSkyPoints = nonSkyPoints! + currentPixelWeight / 255.0
                                }
                            } else {
                                if (blueChannel[index] < localTh) {
                                    finalImageArray[index] = 0
                                    nonSkyPoints = nonSkyPoints! + 1
                                } else {
                                    let currentPixelWeight = LinearScale(blueChannel[index], localTh, minSky)
                                    finalImageArray[index] = Int(currentPixelWeight)
                                    nonSkyPoints = nonSkyPoints! + currentPixelWeight / 255.0
                                }
                            }
                            
                            if (finalImageArray[index] < 0 || finalImageArray[index] > 255) {
                                print("Wrong final image number!!!!")
                            }
                        }
                        
                        //nonClassifiedCount = nonClassifiedCount - positionSize
                    }
                }
            }
            
            searched = nil
            stackToSearch = nil
            positions = nil
            inputProject!.nonSkyPoints = nonSkyPoints
            inputProject!.skyPoints = skyPoints
            inputProject!.threshold = Double(globalHigherThrehold + globalLowerThreshold) / 2
        }
        
/*        let pixelValues = finalImageArray.map{
            value in
            getColorFromRgba(red: UInt8(value), green: UInt8(value), blue: UInt8(value), alpha: 255)
        }
*/

    }
    
    private func convertPixelMapBackToImage() {
        
        let pixelValues = finalImageArray.map{
            value in getColorFromRgba(red: UInt8(value), green: UInt8(value), blue: UInt8(value), alpha: 255)
        }
        
        
        if let outputCGImage = imageFromPixelValues(pixelValues: pixelValues, width: width!, height: height!) {
            inputProject?.edittedImage = UIImage(cgImage: outputCGImage, scale: inputProject!.originalImage!.scale, orientation: inputProject!.originalImage!.imageOrientation)
        }
    }
    

    
    private func getTheHolePixelsCounts(pixelCount pixel: Int) -> (Int, Int, Int, Int, Int) {
        
        
        
        var treeCounts = 0
        var skyCounts = 0
        var positionCount = 0
        var minSky = 255
        var maxTree = 0
        var maxMixed = globalLowerThreshold
        var minMixed = globalHigherThrehold
        var stackStart = 0
        var stackEnd = 1
        
        stackToSearch![0] = pixel
        
        searched![pixel] = true
        
        while (stackStart < stackEnd) {
            
            let  pixelCount = stackToSearch![stackStart]
            
            switch finalImageArray[pixelCount] {
            case -1:
                positions![positionCount] = pixelCount
                positionCount = positionCount + 1
                if (!searched![pixelCount - 1]) {stackToSearch![stackEnd] = pixelCount - 1; stackEnd = stackEnd + 1; searched![pixelCount - 1] = true}
                if (!searched![pixelCount + 1]) {stackToSearch![stackEnd] = pixelCount + 1; stackEnd = stackEnd + 1; searched![pixelCount + 1] = true}
                if (!searched![pixelCount + width!]) {stackToSearch![stackEnd] = pixelCount + width!; stackEnd = stackEnd + 1; searched![pixelCount + width!] = true}
                if (!searched![pixelCount - width!]) {stackToSearch![stackEnd] = pixelCount - width!; stackEnd = stackEnd + 1; searched![pixelCount - width!] = true}
                //minMixed = min(minMixed, blueChannel[pixelCount])
                //maxMixed = max(maxMixed, blueChannel[pixelCount])
                
            case 0:
                treeCounts = treeCounts + 1
                maxTree = max(maxTree, blueChannel[pixelCount])
            case 255:
                skyCounts = skyCounts + 1
                minSky = min(minSky, blueChannel[pixelCount])
            default:
                print("something wrong with the outer classification! ::: \(blueChannel[pixelCount])")
            }
            stackStart = stackStart + 1
        }
        
        if (stackEnd < Int(nonClassifiedCount / 20)) {
            for i in 0..<stackEnd {
                searched![stackToSearch![i]] = false
            }
            
        } else {
            searched = [Bool](repeating: false, count: width! * height!)
        }
 
        
        
        //searched = [Bool](repeating: false, count: width! * height!)
        /*var searchSet : Set = [pixel]
        var treeCounts = 0
        var skyCounts = 0
        var positionCount = 0
        var minSky = 255
        var maxTree = 0
        var maxMixed = globalHigherThrehold
        var minMixed = globalLowerThreshold
        var stackStart = 0
        var stackEnd = 1
        
        stackToSearch![0] = pixel
        
        //searched![pixel] = true
        
        while (stackStart < stackEnd) {
            
            let  pixelCount = stackToSearch![stackStart]
            
            switch finalImageArray[pixelCount] {
            case -1:
                positions![positionCount] = pixelCount
                positionCount = positionCount + 1
                if (!searchSet.contains(pixelCount - 1)) {stackToSearch![stackEnd] = pixelCount - 1; stackEnd = stackEnd + 1; searchSet.insert(pixelCount - 1)}
                if (!searchSet.contains(pixelCount + 1)) {stackToSearch![stackEnd] = pixelCount + 1; stackEnd = stackEnd + 1; searchSet.insert(pixelCount + 1)}
                if (!searchSet.contains(pixelCount + width!)) {stackToSearch![stackEnd] = pixelCount + width!; stackEnd = stackEnd + 1; searchSet.insert(pixelCount + width!)}
                if (!searchSet.contains(pixelCount - width!)) {stackToSearch![stackEnd] = pixelCount - width!; stackEnd = stackEnd + 1; searchSet.insert(pixelCount - width!)}
                //minMixed = min(minMixed, blueChannel[pixelCount])
                //maxMixed = max(maxMixed, blueChannel[pixelCount])
                
            case 0:
                treeCounts = treeCounts + 1
                maxTree = max(maxTree, blueChannel[pixelCount])
                if (blueChannel[pixelCount] > globalLowerThreshold) {
                    print("Wrong Search!")
                }
            case 255:
                skyCounts = skyCounts + 1
                minSky = min(minSky, blueChannel[pixelCount])
                if (blueChannel[pixelCount] < globalHigherThrehold) {
                    print("Wrong search 2")
                }
            default:
                print("something wrong with the outer classification! ::: \(blueChannel[pixelCount])")
            }
            stackStart = stackStart + 1
        }*/

        
        if (treeCounts == 0) {maxTree = minMixed}
        if (skyCounts == 0) {minSky = maxMixed}
        holeCounts = holeCounts + 1
        classifiedMixedPixelCount = classifiedMixedPixelCount + positionCount
        print("Done calculating the \(holeCounts) holes, containing \(positionCount) pixels. Progress : \(classifiedMixedPixelCount) / \(nonClassifiedCount) pixels! ")
        
        return (positionCount, treeCounts, skyCounts, minSky, maxTree)
    }
    
    private func otsus(start: Int, end: Int) -> Int {
        let newCount = histogramCounts[start..<end]
        let total = Double(newCount.reduce(0, +))
        var sumB  = 0.0
        var wB = 0.0
        var wF = 0.0
        var maximum = 0.0
        var sum1 = 0.0
        var mF  = 0.0
        var between = 0.0
        var level = 0
        
        for ii in start ..< end {
            sum1 = sum1 + Double(ii * histogramCounts[ii])
        }
        
        for ii in start ..< end {
            wB = wB + Double(histogramCounts[ii])
            wF = total - wB
            if (wB != 0 ) && (wF != 0) {
                sumB = sumB + Double(ii * histogramCounts[ii])
                mF = (sum1 - sumB) / wF
                between = wB * wF * ((sumB / wB) - mF) * ((sumB / wB) - mF)
                if (between >= maximum) {
                    level = ii
                    maximum = between
                }
            }
        }
        return level
    }
    
    private struct Constant {
        static var clusterRidlerInitValue = 128.0
    }
    
    //private var edittedImage : UIImage?
    //private var combinedImage : UIImage?
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
    
    private var filteredPixelsCount : [Double] = []
    private var colorThreshold = 128.0
    private var blueChannel : [Int] = []
    private var redChannel : [Int] = []
    private var finalImageArray : [Int] = []
    
    //typealias selectedMethod = averageRGB
    //var selectedMethod = averageRGB
    
    private func clusterRidlerAlgorithm(colorThreshold : Double) -> Double {
        var brightAverage = AverageCalculator()
        var darkAverage = AverageCalculator()
        
        for colorValue in filteredPixelsCount {
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
            width            = inputCGImage!.width
            height           = inputCGImage!.height
            let bytesPerPixel    = 4
            let bitsPerComponent = 8
            let bytesPerRow      = bytesPerPixel * width!
            let bitmapInfo       = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            let context = CGContext(data: nil, width: width!, height: height!, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
            context?.draw(inputCGImage!, in: CGRect(x:0, y:0, width:CGFloat(width!), height:CGFloat(height!)))
            
            
            let uncasteddata = UnsafeRawPointer(context!.data)
            let pixelBuffer = uncasteddata?.assumingMemoryBound(to: UInt32.self)
            var currentPixel = pixelBuffer!
            
            blueChannel = [Int](repeating: 0, count: width! * height!)
            redChannel = [Int](repeating: 0, count: width! * height!)
            
            radious = min(height!, width!) / 2
            
            var count = 0
            for  h in 0..<Int(height!) {
                for  w in 0..<Int(width!) {
                    let pixel = currentPixel.pointee
                    //let pixel = currentPixel
                    let brightness = colorFilter(Double(getRedComponent(color: pixel)) , Double(getBlueComponent(color:pixel)) , Double(getGreenComponent(color:pixel)) )
                    //filteredPixelsCount![h * width + w] = brightness
                    let xx = abs(h - height! / 2)
                    let yy = abs(w - width! / 2)
                    if (pow(Double(xx), 2) + pow(Double(yy), 2) < pow(Double(radious!), 2)) {
                        histogramCounts[Int(brightness) + 1] = histogramCounts[Int(brightness) + 1] + 1
                        blueChannel[count] = Int(getBlueComponent(color: pixel))
                        redChannel[count] = Int(getRedComponent(color: pixel))
                    }
                    currentPixel = currentPixel + 1
                    count = count + 1
                }
            }
            
            print("Done calculating pixels count!")
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
                let brightness = filteredPixelsCount[h * width + w]
                
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




















