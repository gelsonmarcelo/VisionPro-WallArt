//
//  WallArtApp.swift
//  WallArt
//
//  Created by Letras on 25/10/23.
//

import SwiftUI

@main
struct WallArtApp: App {
    
    @State private var viewModel = ViewModel()
    
    init() {
        ImpactParticleSystem.registerSystem()
        ProjectileComponent.registerComponent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }.windowStyle(.plain)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(viewModel)
        }
        
        WindowGroup(id: "doodle_canvas") {
            DoodleView()
                .environment(viewModel)
        }
    }
}
