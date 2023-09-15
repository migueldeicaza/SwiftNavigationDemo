//
//  NavMeshDemoApp.swift
//  NavMeshDemo
//
//  Created by Miguel de Icaza on 9/15/23.
//

import SwiftUI

@main
struct NavMeshDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
