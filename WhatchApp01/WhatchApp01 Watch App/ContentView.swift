//
//  ContentView.swift
//  WhatchApp01 Watch App
//
//  Created by AFP PAL 21 on 26/03/26.
//

import SwiftUI
import SpriteKit

// Variabili globali
var scroll = 0.0
public var initDone = false
public var crownSelection = 0
public var moved = false



struct ContentView: View {
    @State public var scrollAmount = 0.0
    
    var body: some View {
        ZStack {
            Text("")
                .hidden()
                .focusable(true)
                .digitalCrownRotation(
                    $scrollAmount,
                    from: -6.9,
                    through: 6.9,
                    by: 0.5,
                    sensitivity: .low,
                    isContinuous: true,
                    isHapticFeedbackEnabled: true
                )
            // Sostituisci il vecchio blocco con questo:
            .onChange(of: scrollAmount) { oldValue, newValue in
                crownSelection = Int(newValue)
                scroll = newValue
                print(crownSelection)
                }
            
            Sview()
        }
        .onTapGesture {
            moved = true
        }
    }
}
