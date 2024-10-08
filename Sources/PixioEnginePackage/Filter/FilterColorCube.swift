

import Foundation
import CoreImage
import SwiftUI

public struct PreviewFilterColorCube : Equatable {
    
    private enum Static {
        static let ciContext = CIContext(options: [.useSoftwareRenderer : false])
        static let heatingQueue = DispatchQueue.init(label: "com.insomniumlabs.PixioEngine.Preheat", attributes: [.concurrent])
    }
    
    public let image: CIImage
    public let filter: FilterColorCube
    public let cgImage: CGImage
    public init(sourceImage: CIImage, filter: FilterColorCube) {
        self.filter = filter
        self.image = filter.apply(to: sourceImage, sourceImage: sourceImage)
        self.cgImage = Static.ciContext.createCGImage(self.image, from: self.image.extent)!
    }
    
    public func preheat() {
        Static.heatingQueue.async {
            _ = Static.ciContext.createCGImage(self.image, from: self.image.extent)
            
        }
    }
}

/// A Filter using LUT Image (backed by CIColorCubeWithColorSpace)
/// About LUT Image -> https://en.wikipedia.org/wiki/Lookup_table
public struct FilterColorCube : Filtering, Equatable {
    
    public static let range: ParameterRange<Double, FilterColorCube> = .init(min: 0, max: 1)
    
    public let filter: CIFilter
    
    public let name: String
    public let identifier: String
    public var amount: Double = 1
    
    public init(
        name: String,
        identifier: String,
        lutImage: Image,
        dimension: Int,
        amount: Double = 1,
        colorSpace: CGColorSpace = CGColorSpace.init(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    ) {
        let filter = ColorCube.makeColorCubeFilter(lutImage: lutImage, dimension: dimension, colorSpace: colorSpace)
        self.init(name: name, identifier: identifier, filter: filter, amount: amount)
    }
    
    public init(name: String,
                identifier: String,
                filter: CIFilter,
                amount: Double = 1
    ){
        self.name = name
        self.identifier = identifier
        self.filter = filter
        self.amount = amount
    }
    
    
    
    
    public func apply(to image: CIImage, sourceImage: CIImage) -> CIImage {
        
        let f = filter.copy() as! CIFilter
        
        f.setValue(image, forKeyPath: kCIInputImageKey)
        if let colorSpace = image.colorSpace {
            f.setValue(colorSpace, forKeyPath: "inputColorSpace")
        }
        
        let background = image
        let foreground = f.outputImage!.applyingFilter(
            "CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(amount)),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        ])
        
        let composition = CIFilter(
            name: "CISourceOverCompositing",
            parameters: [
                kCIInputImageKey : foreground,
                kCIInputBackgroundImageKey : background
        ])!
        
        return composition.outputImage!
        
    }
}
