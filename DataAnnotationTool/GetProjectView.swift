//
//  GetProjectView.swift
//  DataAnnotationTool
//
//  Created by Neal Homan on 11/24/25.
//

import SwiftUI

struct GetProjectView: View {
    let vm = PhotoPickerViewModel()
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            HStack {
                Spacer()
                Button {
                    vm.selectedFolder = openFolderDialog()
                    print("\(vm.selectedFolder!.path)")
                } label: {
                    Text("Open Project")
                }
                Spacer()
            }
                Spacer()
        }
    }
}

#Preview {
    GetProjectView()
}
