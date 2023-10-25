//
//  ContentView.swift
//  WallArt
//
//  Created by Letras on 25/10/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack(alignment: .leading, content: {
            Text("Welcome to Generative Art in Vision Pro")
                .font(.extraLargeTitle2)
        })
        .padding(50)
        .glassBackgroundEffect()
        .onAppear(perform: {
            Task {
                await openImmersiveSpace(id: "ImmersiveSpace")
            }
        })
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
