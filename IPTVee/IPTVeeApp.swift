//
//  IPTVeeApp.swift
//  IPTVee
//
//  Created by Todd Bruss on 9/27/21.
//

import SwiftUI
import AVFoundation

@main
struct IPTVapp: App {
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
   
}

class AppDelegate: NSObject, UIApplicationDelegate {
    

     
    
    func avSession() {
        let avSession = AVAudioSession.sharedInstance()
        
        do {
            avSession.accessibilityPerformMagicTap()
            avSession.accessibilityActivate()
            try avSession.setPreferredIOBufferDuration(0)
            try avSession.setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo, options: [])
            try avSession.setActive(true)
        } catch {
            print(error)
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        avSession()
        
        let plo =  PlayerObservable.plo
        
        plo.videoController.player = PlayerObservable.plo.player
        
        plo.videoController.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        plo.videoController.player?.currentItem?.preferredForwardBufferDuration = 240
        plo.videoController.player?.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        plo.videoController.player?.automaticallyWaitsToMinimizeStalling = true
        
        plo.videoController.requiresLinearPlayback = false
        plo.videoController.showsTimecodes = false
        plo.videoController.showsPlaybackControls = true
        plo.videoController.requiresLinearPlayback = false
        plo.videoController.canStartPictureInPictureAutomaticallyFromInline = true
        plo.videoController.entersFullScreenWhenPlaybackBegins = false
        plo.videoController.showsPlaybackControls = true
        plo.videoController.updatesNowPlayingInfoCenter = false
        
        application.beginReceivingRemoteControlEvents()
        return true
    }
        
    static var interfaceMask = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window:UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.interfaceMask
    }
}
