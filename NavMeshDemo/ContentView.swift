//
//  ContentView.swift
//  NavMeshDemo
//
//  Created by Miguel de Icaza on 9/15/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    static let meshFiles = ["dungeon", "undulating", "nav_test"]
    @State var selectedMesh = ContentView.meshFiles [0]
    @State var diagnostic = ""
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("Navigation Mesh Explorer")

            Picker ("Pick Mesh", selection: $selectedMesh) {
                ForEach (ContentView.meshFiles, id: \.self) {
                    Text ($0)
                }
            }
            Toggle("Load Mesh", isOn: $showImmersiveSpace)
                .toggleStyle(.button)
                .padding(.top, 50)
            Text ($diagnostic)
        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            guard let file = Bundle.main.url(forResource: selectedMesh, withExtension: "obj") else {
                diagnostic = "Could not find the mesh \(selectedMesh).obj")
                return
            }
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
