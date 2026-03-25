//
//  SwiftUIView.swift
//  WatchAndCompanionApp Watch App
//
//  Created by AFP PAL 21 on 25/03/26.
//

import SwiftUI

struct MyTabView: View {
    
    var list: [String] = ["Palermo", "Catania", "Bari", "Messina", "Taranto", "Siracusa"]
    
    var body: some View {
        TabView {
            
            Text("Tab 1")
                .containerBackground(Color.red, for: .tabView)
            Text("Tab 2")
                .containerBackground(Color.blue, for: .tabView)
            Text("Tab 3")
                .containerBackground(Color.yellow, for: .tabView)
            
            List{
                ForEach(list, id: \.self){
                    item in Text(item)
                }
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    MyTabView()
}
