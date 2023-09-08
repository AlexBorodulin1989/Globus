//
//  ContentView.swift
//  Globus
//
//  Created by Aleksandr Borodulin on 11.06.2023.
//

import SwiftUI

struct ContentView: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State var fps = 0

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                GlobusView()
                Text("Hello, world!")
            }
            .padding()

            Text("fps: \(fps)")
                .onReceive(timer) { input in
                    fps = RenderInfo.fps
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
