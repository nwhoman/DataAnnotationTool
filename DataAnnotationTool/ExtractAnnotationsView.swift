//
//  ExtractAnnotationsView.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/14/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ExtractAnnotationsView: View {
    @State var oldText: String = ""
    @State var newText: String = ""
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("Extract Annotations View")
                    .font(.largeTitle)
                    .padding()
                Button {
                    oldText = displayFileData()
                } label: {
                    Text("Select File to Extract Annotations")
                }
                
                HStack {
                    ScrollView {
                        
                        Text("\(oldText.count > 0 ? "\(oldText)" : "No Annotations Extracted")")
                            .lineLimit(nil)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                    Button {
                        newText = extractAnnotations(oldData: oldText)
                    } label: {
                        Text("Extract Annotations")
                    }
                    ScrollView{
                        Text("\(newText.count > 0 ? "\(newText)" : "No Annotations Extracted")")
                            .lineLimit(nil)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                    }
                }
            }
        }
    }
}

#Preview {
    ExtractAnnotationsView()
}

func getFileToExtract() -> URL? {
    let openPanel = NSOpenPanel()
    openPanel.message = "Choose your file"
    openPanel.prompt = "Choose"
    openPanel.allowsOtherFileTypes = false
    openPanel.canChooseFiles = true
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false

    openPanel.runModal()
    print(openPanel.urls) // this contains the chosen folder
    return openPanel.urls.first!
}

func displayFileData() -> String {
    let fileName = getFileToExtract()
    
    let fileContents: String
    do {
        fileContents = try String(contentsOf: fileName!, encoding: .utf8)
    } catch {
        fatalError("Couldn't read file at \(fileName!.path)")
    }
    return fileContents
}

func extractAnnotations(oldData: String) -> String {
    let file: URL = getFileToExtract()!
    print("\(file.deletingLastPathComponent())")
    var jsonString: String = ""
    let decoder = JSONDecoder()
    do {
        let data = try Data(contentsOf: file)
        
        let newData = try decoder.decode([ExtractAnnotationImage].self, from: data)
        var annotationImages: [AnnotationImage] = []
        for item in newData {
            var annotations: [Annotation] = []
            for result in item.annotation[0].results {
                let coordinate = Coordinate(x: result.x, y: result.y, width: result.width, height: result.height)
                let annotation = Annotation(label: result.label, coordinates: coordinate)
                annotations.append(annotation)
            }
            let annotationImage = AnnotationImage(imagefilename: String(item.imagefilename.split(separator: "-")[1]), annotation: annotations)
            annotationImages.append(annotationImage)
        }
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let jsonData = try jsonEncoder.encode(annotationImages)
        jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        
        let path = file.deletingLastPathComponent()
        let name = path.lastPathComponent + "-new.json"
        
        let newPath = path.appending(path: name)
        print("\(newPath)")
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.directoryURL = path
        savePanel.nameFieldStringValue = name
        savePanel.prompt = "Save json file"
        savePanel.begin { response in
            if response == .OK {
                guard let url = savePanel.url else { return }
                do {
                    try jsonData.write(to: url)
                } catch {
                    print("\(error): couldn't write to file")
                }
            }
        }
        
            
    } catch {
        print("\(error)")
        fatalError("Couldn't decode data")
    }
    
    
    return jsonString
}
