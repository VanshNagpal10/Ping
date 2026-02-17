//
//  PingApp.swift
//  Ping - Packet World
//
//  A Narrative Journey Through the Internet
//

import SwiftUI

@main
struct PingApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                #if os(iOS)
                .onAppear {
                    // Request landscape on first window scene
                    guard let windowScene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene }).first else { return }
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
                #endif
        }
    }
}

#if os(iOS)
/// Locks the app to landscape orientations via the supported orientations mask.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return .landscape
    }
}
#endif
