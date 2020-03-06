//
//  ContentView.swift
//  Camshot
//
//  Created by Timi Tejumola on 06/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            GridStack(rows: 3, columns: 3) { row, col in
                Image("default")
                   .renderingMode(.original)
                    .cornerRadius(10)
                .shadow(color: .black, radius: 1)
            }
                .navigationBarTitle("Camshot")
            .navigationBarItems(trailing:
                Button(action: showCam) {
                    Image("cam-icon")
                }
            )
        }
    }
    
    private func showCam(){
        print("Edit button pressed...")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
