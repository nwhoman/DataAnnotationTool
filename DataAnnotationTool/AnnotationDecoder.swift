//
//  AnnotationDecoder.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/15/25.
//

import AppKit
import Foundation
import SwiftUI

struct Coordinate: Codable, Hashable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

struct Annotation: Codable, Hashable {
    let label: String
    let coordinates: Coordinate
    
    init(label: String, coordinates: Coordinate) {
        self.label = label
        self.coordinates = coordinates
    }
}

struct AnnotationImage: Codable, Hashable {
    let imagefilename: String
    let annotation: [Annotation]
    
    init(imagefilename: String, annotation: [Annotation]) {
        self.imagefilename = imagefilename
        self.annotation = annotation
    }
    
}

struct AnnotationImageWithImage: Hashable {
    let image: NSImage
    let color: Color
    let annotationImage: AnnotationImage
    
    init(image: NSImage, color: Color, annotationImage: AnnotationImage) {
        self.image = image
        self.color = color
        self.annotationImage = annotationImage
    }
}

struct ExtractAnnotationImage: Codable {
    let imagefilename: String
    let annotation: [ExtractAnnotation]
    
    enum CodingKeys: String, CodingKey {
        case imagefilename = "file_upload"
        case annotation = "annotations"
    }
    
    struct ExtractAnnotation: Codable {
        let results: [Result]
        
        enum CodingKeys: String, CodingKey {
            case results = "result"
        }
    }
    
    struct Result: Codable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let label: String
        
        enum CodingKeys: CodingKey {
            case value
        }
        enum LabelCodingKeys: String, CodingKey {
            case label = "rectanglelabels"
            case x, y, width, height
        }
        
        init(from decoder: any Decoder) throws {
            let valueContainer = try decoder.container(keyedBy: CodingKeys.self)
            let labelContainer = try valueContainer.nestedContainer(keyedBy: LabelCodingKeys.self, forKey: .value)
            label = try labelContainer.decode([String].self, forKey: .label).first!
            x = try labelContainer.decode(Double.self, forKey: .x)
            y = try labelContainer.decode(Double.self, forKey: .y)
            width = try labelContainer.decode(Double.self, forKey: .width)
            height = try labelContainer.decode(Double.self, forKey: .height)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            var labelContainer = container.nestedContainer(keyedBy: LabelCodingKeys.self, forKey: .value)
            try labelContainer.encode(label, forKey: .label)
            try labelContainer.encode(x, forKey: .x)
            try labelContainer.encode(y, forKey: .y)
            try labelContainer.encode(width, forKey: .width)
            try labelContainer.encode(height, forKey: .height)
        }
    }
}

struct Box: Hashable {
    var rect: CGRect
    var color: Color = .red
    var coordinates: Coordinates
    var label: String
    struct Coordinates: Hashable {
        var x: CGFloat
        var y: CGFloat
        var height: CGFloat
        var width: CGFloat
        
        init(x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat) {
            self.x = x + (width / 2.0)
            self.y = y + (height / 2.0)
            self.height = height
            self.width = width
        }
    }
    init(rect: CGRect, color: Color = .red, label: String) {
        self.rect = rect
        self.color = color
        self.coordinates = Coordinates(x: rect.minX, y: rect.minY, height: rect.height, width: rect.width)
        self.label = label
    }
    // x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
    
}


