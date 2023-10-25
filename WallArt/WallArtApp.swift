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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }.windowStyle(.plain)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
