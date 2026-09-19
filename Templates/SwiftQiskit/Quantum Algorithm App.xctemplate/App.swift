//
//  ___PACKAGENAME___App.swift
//  ___PACKAGENAME___
//

import SwiftUI

@main
struct ___PACKAGENAME___App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            #if os(macOS)
                .frame(minWidth: 480, minHeight: 560)
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 560, height: 680)
        .windowResizability(.contentMinSize)
        #endif
    }
}
