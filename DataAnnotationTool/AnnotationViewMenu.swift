//
//  AnnotationViewMenu.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/26/25.
//

import SwiftUI

struct AnnotationViewMenu: View {
    @StateObject var viewModel: PhotoPickerViewModel
    @Binding var scaleFactor: CGFloat
    @Binding var boxes: [Box]
    @Binding var undoneBoxes: [Box]
    
    @Binding var currentBox: Box
    @Binding var labels: [String: Color]
    @Binding var newLabel: String
    @Binding var selectedLabel: String
    @Binding var pendingChanges: Bool
    
    //@State var image: CGImage?
    let labelColors: [Color] = [.red, .orange, .green, .blue, .pink, .purple, .yellow, .black, .cyan]
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 10) {
                Text("Zoom Level: \(String(format: "%0.2f", scaleFactor))")
                    .padding(.horizontal, 10)
                    .padding(.top, 15)
                HStack {
                    Spacer()
                    Button {
                        scaleFactor = scaleFactor + 0.25
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .padding(.horizontal, 10)
                    Button {
                        undoneBoxes.append(boxes.popLast()!)
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(boxes.isEmpty)
                    .padding(.horizontal, 10)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button {
                        if scaleFactor != 0.25 {
                            scaleFactor -= 0.25
                        }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .padding(.horizontal, 10)
                    Button {
                        boxes.append(undoneBoxes.popLast()!)
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(undoneBoxes.isEmpty)
                    .padding(.horizontal, 10)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button {
                        savePictureAnnotations(viewModel: viewModel, boxes: boxes, fileName: viewModel.selectedFolder!.lastPathComponent)
                        boxes = []
                        undoneBoxes = []
                        scaleFactor = 1.0
                    } label: {
                        HStack {
                            Text("Save Image")
                            Image(systemName: "square.and.arrow.down")
                        }
                        
                    }
                    .disabled(boxes.isEmpty)
                    .padding(.horizontal, 10)
                    Spacer()
                }
                
                Text("New Label:")
                    .padding(.leading, 10)
                TextField("Enter Label Name", text: $newLabel)
                    .padding(.horizontal, 10)
                Button {
                    let color = labelColors[labels.count]
                    labels[newLabel] = color
                    newLabel = ""
                    if labels.count == 1 {
                        selectedLabel = Array(labels.keys).first!
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .padding(.leading, 10)
                ForEach(Array(labels.keys), id: \.self) { label in
                    if label != selectedLabel {
                        Text("\(label)")
                            .foregroundStyle(Color(labels[label]!))
                            .padding(5)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(.white))
                            .onTapGesture {
                                selectedLabel = label
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(labels[label]!), lineWidth: 2)
                            )
                            .padding(.leading, 10)
                    } else {
                        Text("\(label)")
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color(labels[label]!)))
                            .padding(.leading, 10)
                            .onTapGesture {
                                selectedLabel = label
                            }
                    }
                }
            }
            
            .frame(width: 150, height: 500, alignment: .init(horizontal: .leading, vertical: .top))
            .background(.gray.opacity(0.5))
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray, lineWidth: 2))
            .padding()
        }
    }
}

//#Preview {
//    AnnotationViewMenu(viewModel: <#PhotoPickerViewModel#>, scaleFactor: <#Binding<CGFloat>#>, boxes: <#Binding<[Box]>#>, undoneBoxes: <#Binding<[Box]>#>, currentBox: <#Binding<Box>#>, labels: <#Binding<[String : Color]>#>, newLabel: <#Binding<String>#>, selectedLabel: <#Binding<String>#>, pendingChanges: <#Binding<Bool>#>)
//}
