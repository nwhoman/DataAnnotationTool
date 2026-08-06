//
//  PublicFunctions.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/20/25.
//

import AppKit
import Foundation

func getJpegData(image: NSImage, compressionQuality: CGFloat = 1.0) -> Data? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return nil
    }
    let bitMapRep = NSBitmapImageRep(cgImage: cgImage)
    
    let properties: [NSBitmapImageRep.PropertyKey: Any] = [
        .compressionFactor: compressionQuality as NSNumber
    ]
    
    guard let jpegData = bitMapRep.representation(using: .jpeg, properties: properties) else {
        return nil
    }
    
    return jpegData
}

func openFolderDialog() -> URL? {
    let dialog = NSOpenPanel()
    dialog.title = "Choose a folder"
    dialog.showsHiddenFiles = false
    dialog.canChooseDirectories = true
    dialog.canCreateDirectories = true
    dialog.canChooseFiles = false
    dialog.allowsMultipleSelection = false
    
    let result = dialog.runModal()
    
    switch result {
    case .OK:
        print("\(dialog.url!.path)")
        return dialog.url
    default:
        return nil

    }
}

func savePictureAnnotations(viewModel: PhotoPickerViewModel, boxes: [Box], fileName: String) {
    let vm = viewModel
    let index = vm.imagesAnnotated.count + vm.existingImagesAnnotated.count
    let newFileName: String = fileName + "_\(String(index)).jpeg"
    var annotations: [Annotation] = []
    for box in boxes {
        let coord: Coordinate = Coordinate(x: box.coordinates.x, y: box.coordinates.y, width: box.coordinates.width, height: box.coordinates.height)
        let newAnnotation: Annotation = Annotation(label: box.label, coordinates: coord)
        annotations.append(newAnnotation)
    }
    let annotationImage: AnnotationImage = AnnotationImage(imagefilename: newFileName, annotation: annotations)
    let annotationWithImage: AnnotationImageWithImage = AnnotationImageWithImage(image: vm.selectedImage!, color: boxes.first!.color, annotationImage: annotationImage)
    vm.imagesAnnotated.append(annotationWithImage)
    vm.selectedImage = nil
    vm.folderContents! += 1
}

func checkSavedImages(image: NSImage, savedImages: [AnnotationImageWithImage]) -> AnnotationImageWithImage? {
    for savedImage in savedImages {
        if savedImage.image.isEqual(to: image) {
            return savedImage
        }
    }
    return nil
}

func restoreImageSavedProperties(vm: PhotoPickerViewModel, annotationImage: AnnotationImageWithImage) -> [Box] {
    var boxes: [Box] = []
    vm.imagesAnnotated.removeAll(where: { $0.image.isEqual(to: annotationImage.image) })
    for annotation in annotationImage.annotationImage.annotation {
        let rect = CGRect(x: CGFloat(annotation.coordinates.x - annotation.coordinates.width/2), y: CGFloat(annotation.coordinates.y - annotation.coordinates.height/2), width: CGFloat(annotation.coordinates.width), height: CGFloat(annotation.coordinates.height))
        let newBox: Box = Box(rect: rect, color: annotationImage.color, label: annotation.label)
        boxes.append(newBox)
    }
    return boxes
}

func writeAnnotationsToFile(vm: PhotoPickerViewModel) {
    //var startingIndex: Int = vm.folderContents!
    //let images = vm.imagesAnnotated
    //checkFolderContents(vm: vm)
    for image in vm.imagesAnnotated { // @Published var imagesAnnotated: [AnnotationImageWithImage] = []
        writeImageToFile(baseUrl: vm.selectedFolder!, image: image.image, name: "\(vm.existingImagesAnnotated.count)")
        vm.existingImagesAnnotated.append(image.annotationImage)
    }

    do {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let jsonData = try jsonEncoder.encode(vm.existingImagesAnnotated)
    
        let path = vm.selectedFolder!
        let name = "annotations.json" //path.lastPathComponent +
        
        let newPath = path.appending(path: name)
        print("\(newPath)")
        try jsonData.write(to: newPath)
    } catch {
        print("\(error.localizedDescription): couldn't write to file")
        
    }
    vm.imagesAnnotated = []
    //vm.existingImagesAnnotated = []
}

func writeImageToFile(baseUrl: URL, image: NSImage, name: String) {
    let fullName = baseUrl.lastPathComponent + "_" + name + ".jpeg"
    let url = baseUrl.appendingPathComponent(fullName)
    do {
        let jpegData = getJpegData(image: image)
        try jpegData!.write(to: url)
    } catch {
        print("\(error): couldn't write to file")
    }
}

func checkFolderContents(vm: PhotoPickerViewModel) {
    let fm = FileManager.default
    var images = 0
    var json = ""
    let files = try? fm.contentsOfDirectory(at: vm.selectedFolder!, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
    if let files = files {
        for file in files {
            if file.pathExtension == "jpeg" {
                images += 1
                print("\(vm.inspectImages)")
                if vm.inspectImages {
                    if let data = try? Data(contentsOf: file) {
                        if let nsImage = NSImage(data: data) {
                            vm.selectedImages?.append(nsImage)
                        }
                    }
                }
                
            }
            if file.pathExtension == "json" {
                json = try! String(contentsOf: file, encoding: .utf8)
                print(json)
                vm.existingImagesAnnotated.append(contentsOf: decodeImageAnnotationJSON(jsonFile: file) ?? [])
                //vm.folderContents = vm.existingImagesAnnotated.count
            }
        }
    }
    vm.folderContents = images
}

func decodeImageAnnotationJSON(jsonFile: URL) -> [AnnotationImage]? {
    do {
        let jsonData = try Data(contentsOf: jsonFile)
        let decoder = JSONDecoder()
        let savedAnnotations: [AnnotationImage] = try decoder.decode([AnnotationImage].self, from: jsonData)
        return savedAnnotations
    } catch {
        
    }
    return nil
}


