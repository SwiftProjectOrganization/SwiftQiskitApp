//
//  SwiftQiskitAppApp.swift
//  SwiftQiskitApp
//

import SwiftUI

@main
struct SwiftQiskitAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            #if os(macOS)
                .frame(minWidth: 900, minHeight: 600)
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 640)
        .windowResizability(.contentMinSize)
        #endif
    }
}
