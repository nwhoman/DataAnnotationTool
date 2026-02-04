//
//  CoordinateFilesView.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/13/25.
//
import AppKit
import Cocoa
import Foundation
import FileProvider
import SwiftUI
internal import UniformTypeIdentifiers

struct CoordinateFilesView: View {
    @State var showDialog: Bool = false
    @State var folder: URL?
    @State var newName: String = ""
    @State var changedFiles: [String] = []
    @State var filesChanged: Bool = false
    
    let fm = FileManager.default
    
    var bland: URL {
        
        return fm.homeDirectoryForCurrentUser
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack{
                TextField("Name to coordinate files to folder", text: $newName)
                    .padding()
                Button {
                    filesChanged = true
                    changeFolderAndPicNames(fileName: newName, changedFiles: &changedFiles)
                } label: {
                    HStack{
                        Spacer()
                        Text("Coordinate names")
                        Spacer()
                        
                    }
                }
                .frame(width: geo.size.width/4, height: 20.0)
                .padding()
                Spacer()
                ScrollView(.vertical, showsIndicators: false){
                    if filesChanged {
                        ForEach(changedFiles, id: \.self) { file in
                            Text(file)
                        }
                    }
                }
                
            }
            .frame(width: geo.size.width/2, height: geo.size.height)
//            .fileImporter(isPresented: $showDialog, allowedContentTypes: [.folder, .directory, .fileURL], allowsMultipleSelection: false) { result in
//                switch result {
//                case .success(let urls):
//                    folder = urls.first
//                case .failure(let error):
//                    print(error.localizedDescription)
//                }
//                showDialog = false
//            }
        }
    }
}

#Preview {
    CoordinateFilesView()
}

func promptForWorkingDirectoryPermission() -> URL? {
    let openPanel = NSOpenPanel()
    openPanel.message = "Choose your directory"
    openPanel.prompt = "Choose"
    openPanel.allowsOtherFileTypes = false
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true

    let response = openPanel.runModal()
    print(openPanel.urls) // this contains the chosen folder
    return openPanel.urls.first!
}

func changeFolderAndPicNames(fileName: String, changedFiles: inout [String]) -> Void {
    let picsFolder: URL = promptForWorkingDirectoryPermission()!
    let fm = FileManager.default
    
    let newFolder: URL = picsFolder.appendingPathComponent(fileName)
    
    do {
        try fm.createDirectory(at: newFolder, withIntermediateDirectories: false)
        changedFiles.append("\(newFolder) created")
    } catch {
        print("Failed to add \(newFolder) /n Error: \(error)")
    }
    
    let items = try! fm.contentsOfDirectory(atPath: picsFolder.path)
    var i: Int = 0
    for item in items {
        var newName: String = ""
        let picToMove = picsFolder.path + "/\(item)"
        if item.hasSuffix(".json") {
            newName = "\(fileName).json"
        } else {
            newName = "\(fileName)_\(i).jpeg"
        }
        let newPath = newFolder.path + "/\(newName)"
        do {
            try fm.moveItem(at: URL(fileURLWithPath: picToMove), to: URL(fileURLWithPath: newPath))
            print("\(item) changed to \(newName)")
            changedFiles.append("\(item) changed to \(newName)")
            i += 1
        } catch {
            print("Failed to move \(picToMove) to \(newPath)")
        }
    
    }
    
    
}
