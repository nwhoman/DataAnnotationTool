//
//  PhotoAnnotationView.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/18/25.
//

import PhotosUI
import SwiftUI
import AppKit
internal import Combine

@MainActor
final class PhotoPickerViewModel: ObservableObject {
    @Published var selectedImages: [NSImage]? = [] // private(set)
    @Published var imageSelection: [PhotosPickerItem] = [] {
        didSet {
            setImage(from: imageSelection)
        }
    }
    @Published var selectedImage: NSImage?
    
    @Published var selectedFolder: URL? {
        didSet {
            createBookmark(for: selectedFolder!)
            do {
                folderContents = try FileManager.default.contentsOfDirectory(at: selectedFolder!, includingPropertiesForKeys: [.nameKey]).count
            } catch {
                print("Could not get number of images in folder: \(error)")
            }
        }
    }
    @Published var folderSecurityBookmark: Data?
    @Published var folderContents: Int? = 0
    @Published var jsonContent: String? = ""
    @Published var imagesAnnotated: [AnnotationImageWithImage] = []
    @Published var existingImagesAnnotated: [AnnotationImage] = []
    @Published var inspectImages: Bool = false

    private func setImage(from selection: [PhotosPickerItem]?) {
        guard let selection else { return }
        
        Task {
            if !selectedImages!.isEmpty {
                selectedImages = []
            }
            for item in selection {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    if let nsImage = NSImage(data: data) {
                        selectedImages?.append(nsImage)
                    
                    }
                }
            }
            return
        }
    }
    private func createBookmark(for url: URL) {
        do {
            folderSecurityBookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }
    
}

struct PhotoAnnotationView: View {
    @StateObject private var viewModel = PhotoPickerViewModel()
    
    @State var boxes: [Box] = []
    @State var undoneBoxes: [Box] = []
    @State var currentBox: Box = Box(rect: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0), color: .blue, label: "")
    @State var scaleFactor: CGFloat = 1.0
    @State var labels: [String: Color] = [:]
    @State var newLabel: String = ""
    @State var selectedLabel: String = ""
    @State var pendingChanges: Bool = false
    @State var imagesPresent: Bool = false
    //@State var image: CGImage?
    let labelColors: [Color] = [.red, .orange, .green, .blue, .pink, .purple, .yellow, .black, .cyan]
    let fm = FileManager.default
    var cacheDirectory: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    
    var body: some View {
        GeometryReader { geo in
            
            ScrollView() {
                HStack() {
                    HStack {
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading){
                                if viewModel.selectedFolder != nil {
                                    Text(viewModel.selectedFolder!.path)
                                        .font(.caption)
                                        
                                        .frame(width: 150, height: 50)
                                } else {
                                    Button {
                                        let url = openFolderDialog()
                                        viewModel.selectedFolder = url
                                        if let contents = try? fm.contentsOfDirectory(at: url!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles ) {
                                            print("contents: \(contents)")
                                            imagesPresent = true
                                        }
                                    } label: {
                                        Text("Open Folder")
                                    }
                                    
                                    .frame(width: 150, height: 50)
                                }
                                    
                                PhotosPicker(selection: $viewModel.imageSelection, maxSelectionCount: 5, selectionBehavior: .default) {
                                    Text("Select Images")
                                }
                                
                                .frame(width: 150, height: 50)
                                Button {
                                    
                                    guard let url = viewModel.selectedFolder else { return }
                                    writeAnnotationsToFile(vm: viewModel)
                                    
                                } label: {
                                    Text("Save Images")
                                }
                                
                                .frame(width: 150, height: 50)
                            } // end of vstack aroung buttons
                            .frame(width: 150, height: 200, alignment: .init(horizontal: .leading, vertical: .top))
                            .background(.gray.opacity(0.5))
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray, lineWidth: 2))
                            
                            .padding()
                            AnnotationViewMenu(viewModel: viewModel, scaleFactor: $scaleFactor, boxes: $boxes, undoneBoxes: $undoneBoxes, currentBox: $currentBox, labels: $labels, newLabel: $newLabel, selectedLabel: $selectedLabel, pendingChanges: $pendingChanges)
                            Spacer()
                        } // end of vstack around menus
                        VStack {
                            Spacer()
                                .frame(height: 255)
                                
                            VStack {
                                ForEach($boxes, id: \.self) { $box in
                                    VStack(alignment: .leading) {
                                        Text("\(box.label)")
                                        Text("x: \((String(format: "%0.3f", box.coordinates.x)))")
                                        //Text("x': \(box.rect.minX)")
                                        Text("y: \((String(format: "%0.3f", box.coordinates.y)))")
                                        Text("width: \((String(format: "%0.3f", box.coordinates.width)))")
                                        Text("height: \((String(format: "%0.3f", box.coordinates.height)))")
                                    }
                                    .padding()
                                }
                            }
                            .padding()
                            .frame(width: 150, height: 700, alignment: .init(horizontal: .leading, vertical: .top))
                            .background(.gray.opacity(0.5))
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray, lineWidth: 2))
                            Spacer()
                        }
                        
                    }// end of hstack around menus
                    .frame(width: geo.size.width/3, height: 2000, alignment: .init(horizontal: .center, vertical: .top))
                    .border(Color.gray, width: 1)
                    Spacer()
                    VStack(alignment: .leading) {
                        //if !viewModel.selectedImages!.isEmpty {
                            
                            if let images = viewModel.selectedImages {
                                
                                ScrollView(.horizontal, showsIndicators: true) {
                                    HStack {
                                        ForEach(images, id: \.self) { image in
                                            Button {
                                                if !boxes.isEmpty {
                                                    pendingChanges.toggle()
                                                } else {
                                                    if let savedImage = checkSavedImages(image: image , savedImages: viewModel.imagesAnnotated)  {
                                                        viewModel.selectedImage = savedImage.image
                                                        
                                                        boxes = restoreImageSavedProperties(vm: viewModel, annotationImage: savedImage)
                                                        
                                                    } else {
                                                        viewModel.selectedImage = image
                                                    }
                                                }
                                            } label: {
                                                ZStack {
                                                    VStack {
                                                        Image(nsImage: image)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 200, height: 200)
                                                            .cornerRadius(10)
                                                        Text("\(image.size.width)x\(image.size.height)")
                                                        
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        
                        if viewModel.selectedImage != nil {
                            
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack {
                                    ScrollView([.horizontal, .vertical]) {
                                        Image(nsImage: viewModel.selectedImage!)
                                            .resizable()
                                            .scaledToFit()
                                        //.scaleEffect(scaleFactor)
                                        //                                .frame(width: 600, height: 600)
                                            .cornerRadius(10)
                                            .overlay(alignment: .top) {
                                                Canvas(opaque: true, colorMode: .nonLinear, rendersAsynchronously: false) { context, size in
                                                    
                                                    for box in boxes {
                                                        context.stroke(Path(box.rect), with: .color(box.color), lineWidth: 2)
                                                    }
                                                    context.stroke(Path(currentBox.rect), with: .color(currentBox.color), lineWidth: 2)
                                                    
                                                }
                                                .gesture(
                                                    
                                                    DragGesture()
                                                        .onChanged{ value in
                                                            //currentLine.points.append(value.location)
                                                            //lines.append(currentLine)
                                                            
                                                            currentBox = Box(rect: CGRect(x: value.startLocation.x, y: value.startLocation.y, width: abs(value.startLocation.x - value.location.x), height: abs(value.startLocation.y - value.location.y)), color: labels[selectedLabel]!, label: selectedLabel)
                                                        }
                                                        .onEnded { value in
                                                            
                                                            boxes.append(currentBox)
                                                            currentBox = Box(rect: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0), color: .blue, label: "")
                                                        }
                                                    
                                                    
                                                    
                                                )
                                                .disabled(selectedLabel.isEmpty)
                                            }
                                            .scaleEffect(scaleFactor)
                                        
                                        
                                        
                                    } //end of canvas view
                                    .frame(width: 700, height: 700)
                                }
                            }
                        } else {
                            Spacer()
                        }
                        
                        ScrollView(.horizontal) {
                            HStack {
                                let images = viewModel.imagesAnnotated
                                ForEach(images, id: \.self) { image in
                                    let annotations = image.annotationImage.annotation
                                    HStack {
                                        Image(nsImage: image.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 200)
                                            .cornerRadius(10)
                                        ForEach(annotations, id: \.self) { annotation in
                                            VStack(alignment: .leading) {
                                                Text(annotation.label)
                                                Text("x: \(String(format: "%0.3f", annotation.coordinates.x))")
                                                Text("y: \(String(format: "%0.3f", annotation.coordinates.y))")
                                                Text("width: \(String(format: "%0.3f", annotation.coordinates.width))")
                                                Text("height: \((String(format: "%0.3f", annotation.coordinates.height)))")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        } // end of bottom scroll view
                        Spacer()
                    } // end of vstack on right
                    .frame(width: 700, height: 2000)
                    .border(Color.gray, width: 1)
                    Spacer()
            } //end of main hstack
        }
        }
        .alert(isPresented: $pendingChanges, content: {
            Alert(title: Text("Save Changes?"), message: Text("Do you want to save your changes to the current image?"),
                primaryButton: .default(Text("Save"), action:                            {
                savePictureAnnotations(viewModel: viewModel, boxes: boxes, fileName: viewModel.selectedFolder!.lastPathComponent)
                boxes = []
                undoneBoxes = []
            }), secondaryButton: .cancel(Text("Cancel"), action: {
                boxes = []
                undoneBoxes = []
                viewModel.selectedImage = nil
            }))
        })
        .alert(isPresented: $imagesPresent, content: {
            Alert(title: Text("Images Found"), message: Text("Do you want to open the images for annotation?"),
                primaryButton: .default(Text("Yes"), action: {
                viewModel.inspectImages = true
                print("\(viewModel.inspectImages)")
                checkFolderContents(vm: viewModel)

            }), secondaryButton: .cancel(Text("No"), action: {
                imagesPresent = false
                checkFolderContents(vm: viewModel)

            }))
        })
//        .onAppear {
//            
//            guard let folder = viewModel.selectedFolder  else {
//                return
//            }
//            do {
//                viewModel.folderContents = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.nameKey]).count
//            } catch {
//                print("Could not get number of images in folder: \(error)")
//            }
//        }
    }
        
}

#Preview {
    PhotoAnnotationView()
}

//                            VStack(alignment: .leading, spacing: 10) {
//                                Text("Zoom Level: \(String(format: "%0.2f", scaleFactor))")
//                                    .padding(.leading, 10)
//                                    .padding(.top, 15)
//                                HStack {
//                                    Button {
//                                        scaleFactor = scaleFactor + 0.25
//                                    } label: {
//                                        Image(systemName: "plus.magnifyingglass")
//                                    }
//                                    .padding(.leading, 10)
//                                    Button {
//                                        undoneBoxes.append(boxes.popLast()!)
//                                    } label: {
//                                        Image(systemName: "arrow.uturn.backward")
//                                    }
//                                    .disabled(boxes.isEmpty)
//                                    .padding(.leading, 10)
//                                }
//                                HStack {
//                                    Button {
//                                        if scaleFactor != 0.25 {
//                                            scaleFactor -= 0.25
//                                        }
//                                    } label: {
//                                        Image(systemName: "minus.magnifyingglass")
//                                    }
//                                    .padding(.leading, 10)
//                                    Button {
//                                        boxes.append(undoneBoxes.popLast()!)
//                                    } label: {
//                                        Image(systemName: "arrow.uturn.forward")
//                                    }
//                                    .disabled(undoneBoxes.isEmpty)
//                                    .padding(.leading, 10)
//                                }
//                                Button {
//                                    savePictureAnnotations(viewModel: viewModel, boxes: boxes, fileName: viewModel.selectedFolder!.lastPathComponent)
//                                    boxes = []
//                                    undoneBoxes = []
//                                } label: {
//                                    HStack {
//                                        Text("Save Image")
//                                        Image(systemName: "square.and.arrow.down")
//                                    }
//
//                                }
//                                .disabled(boxes.isEmpty)
//                                .padding(.leading, 10)
//
//                                Text("New Label:")
//                                    .padding(.leading, 10)
//                                TextField("Enter Label Name", text: $newLabel)
//                                    .padding(.leading, 10)
//                                Button {
//                                    let color = labelColors[labels.count]
//                                    labels[newLabel] = color
//                                    newLabel = ""
//                                    if labels.count == 1 {
//                                        selectedLabel = Array(labels.keys).first!
//                                    }
//                                } label: {
//                                    Image(systemName: "plus")
//                                }
//                                .padding(.leading, 10)
//                                ForEach(Array(labels.keys), id: \.self) { label in
//                                    if label != selectedLabel {
//                                        Text("\(label)")
//                                            .foregroundStyle(Color(labels[label]!))
//                                            .padding(5)
//                                            .background(RoundedRectangle(cornerRadius: 10)
//                                                .fill(.white))
//                                            .onTapGesture {
//                                                selectedLabel = label
//                                            }
//                                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                                            .overlay(
//                                                RoundedRectangle(cornerRadius: 10)
//                                                    .stroke(Color(labels[label]!), lineWidth: 2)
//                                            )
//                                            .padding(.leading, 10)
//                                    } else {
//                                        Text("\(label)")
//                                            .foregroundStyle(.white)
//                                            .padding(5)
//                                            .background(RoundedRectangle(cornerRadius: 10)
//                                                .fill(Color(labels[label]!)))
//                                            .padding(.leading, 10)
//                                            .onTapGesture {
//                                                selectedLabel = label
//                                            }
//                                    }
//                                }
//                            }
//
//                            .frame(width: 150, height: 500, alignment: .init(horizontal: .leading, vertical: .top))
//                            .cornerRadius(10)
//                            .border(Color.gray)
//                            .padding()
