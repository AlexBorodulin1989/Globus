//
//  ContentView.swift
//  Globus
//
//  Created by Aleksandr Borodulin on 11.06.2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            GlobusView()
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
