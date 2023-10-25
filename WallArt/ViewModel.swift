//
//  ViewModel.swift
//  WallArt
//
//  Created by Letras on 25/10/23.
//

import Foundation

enum FlowState {
    case idle
    case intro
    case projectileFlying
    case updateWallArt
}

@Observable
class ViewModel {
    
    var flowState = FlowState.idle
    
}
