//
//  ContentView.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
        

    var body: some View {
        GeometryReader { geo in
            NavigationSplitView {
                ScrollView {
                    VStack {
                        //Spacer()
                        NavigationLink {
                            PhotoAnnotationView()
                        } label: {
                            Text("Create Picture Annotations")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }.padding(10)
                        NavigationLink {
                            CoordinateFilesView()
                        } label: {
                            Text("Coordinate File and File Content Names")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }
                        .padding(10)
                        NavigationLink {
                            ExtractAnnotationsView()
                        } label: {
                            Text("Extract Annotation Data")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }.padding(10)
                        Spacer()
                    }
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200)
                    .toolbar {
                        ToolbarItem {
                            Button(action: addItem) {
                                Label("Add Item", systemImage: "plus")
                            }
                        }
                    }
                }
            } detail: {
                Text("Select an item")
            }
            .frame(minWidth: 500, alignment: .leading)
        }
        
    }

    private func addItem() {
        withAnimation {
            //let newItem = Item(timestamp: Date())
            //modelContext.insert(newItem)
        }
    }

//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}


