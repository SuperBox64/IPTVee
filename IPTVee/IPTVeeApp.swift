//
//  IPTVeeApp.swift
//  IPTVee
//
//  Created by Todd Bruss on 9/27/21.
//

import SwiftUI
import AVFoundation
import iptvKit
import UIKit

@main
struct IPTVapp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var lgo = LoginObservable.shared
    
    
    var body: some Scene {
        WindowGroup {
            
            Text("")
                .withHostingWindow { window in
                    let contentView = ContentView()
                    window?.rootViewController =
                    BlendInHomeIndicatorController(rootView: contentView)
                }
                .statusBar(hidden: isPad)
        }
    }
    
    class BlendInHomeIndicatorController<Content:View>: UIHostingController<Content> {
        override var shouldAutorotate : Bool {
            true
        }
        
        override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
            [.all]
        }
        
        override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
            [.all]
        }
        
        override var prefersHomeIndicatorAutoHidden: Bool {
            false
        }
        
        override var prefersStatusBarHidden: Bool {
            isPad
        }
        
        override var preferredStatusBarStyle: UIStatusBarStyle {
            .default
        }
    }
}

func loadUserDefaults() {
    if let data = UserDefaults.standard.value(forKey:userSettings) as? Data,
       let disk = try? PropertyListDecoder().decode(Config.self, from: data) {
        
        LoginObservable.shared.config = disk
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        startupAVPlayer()
        application.beginReceivingRemoteControlEvents()
        loadUserDefaults()
        runAVSession()
        //HLSxServe.shared.start_HLSx()
        return true
    }
}

struct HostingWindowFinder: UIViewRepresentable {
    var callback: (UIWindow?) -> ()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func withHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
        self.background(HostingWindowFinder(callback: callback))
    }
}

var isPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

var isPhone: Bool {
    UIDevice.current.userInterfaceIdiom == .phone
}

func updatePortrait() -> Bool {
    if UIDevice.current.orientation.isPortrait { return true}
    if UIDevice.current.orientation.isLandscape { return false}
    return isPortraitFallback
}

var isPortraitFallback: Bool {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        return true
    }
    return scene.interfaceOrientation.isPortrait
}
