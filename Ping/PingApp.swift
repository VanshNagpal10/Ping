//
//  PingApp.swift
//  Ping
//
//  A Packet's Odyssey - Swift Student Challenge
//

import SwiftUI

@main
struct PingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
    
    init() {
        // Lock to landscape orientation for iPad
        #if os(iOS)
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        #endif
    }
}
