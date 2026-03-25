//
//  Toolbar_Bottom.swift
//  WatchAndCompanionApp Watch App
//
//  Created by AFP PAL 21 on 25/03/26.
//

import SwiftUI

struct ToolbarBottom: View {
    var body: some View {
        NavigationStack {
            Text("Content here!")
                .toolbar {
                    // Gruppo di controlli posizionati nella parte inferiore
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            print("Previous")
                        } label: {
                            Label("Prev Track", systemImage: "arrow.left")
                        }
                        
                        Button {
                            print("Pause/Play")
                        } label: {
                            Label("Play", systemImage: "pause.fill")
                        }
                        .controlSize(.large)
                        
                        Button {
                            print("Forward")
                        } label: {
                            Label("Forward", systemImage: "arrow.right")
                        }
                    }
                    
                    /* // Sezioni commentate nell'immagine per il posizionamento superiore
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button {
                            print("Previous")
                        } label: {
                            Label("Prev Track", systemImage: "arrow.left")
                        }
                    }
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            print("Forward")
                        } label: {
                            Label("Forward", systemImage: "arrow.right")
                        }
                    }
                    */
                }
        }
    }
}

#Preview {
    ToolbarBottom()
}
