
import AVKit
import SwiftUI
import iptvKit
import MediaPlayer

public var avSession = AVAudioSession.sharedInstance()

public struct AVPlayerView: UIViewControllerRepresentable {
    let streamID: Int
    let name: String
    let streamIcon: String
    
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var pvc = PlayerViewControllerObservable.pvc
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func updateUIViewController(_ videoController: AVPlayerViewController, context: Context) {
        runAVSession()
    }
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        guard let _ = pvc.videoController.player else { return pvc.videoController }
        
        if streamID != plo.previousStreamID || (pvc.videoController.player?.rate == 0 && pvc.videoController.player?.timeControlStatus != .paused) {
            Player.iptv.Action(streamId: streamID, channelName: name, imageURL: streamIcon)
            
            plo.previousStreamID = streamID
            pvc.videoController = setupPlayerToPlay()
            setupRemoteTransportControls()
            pvc.videoController.delegate = context.coordinator
            return pvc.videoController
        } else {
            let player = pvc.videoController.player
            pvc.videoController = AVPlayerViewController()
            pvc.videoController.player = player
            return pvc.videoController
        }
    }
}

public func runAVSession() {
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

public func startupAVPlayer() {
    let pvc = PlayerViewControllerObservable.pvc
    
    pvc.videoController.player = AVPlayer(playerItem: nil)
    pvc.videoController.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
    //pvc.videoController.view.backgroundColor = UIColor.clear
}

public func setupVideoController() -> AVPlayerViewController {
    
    let pvc = PlayerViewControllerObservable.pvc
    guard let _ = pvc.videoController.player else { return pvc.videoController }
    
    pvc.videoController.loadViewIfNeeded()
    pvc.videoController.showsTimecodes = false
    pvc.videoController.entersFullScreenWhenPlaybackBegins = true
    pvc.videoController.updatesNowPlayingInfoCenter = false
    pvc.videoController.showsPlaybackControls = true
    pvc.videoController.requiresLinearPlayback = false
    pvc.videoController.canStartPictureInPictureAutomaticallyFromInline = true
    pvc.videoController.videoGravity = .resizeAspect
    pvc.videoController.accessibilityPerformMagicTap()
    //pvc.videoController.view.backgroundColor = UIColor.clear
    return pvc.videoController
}

public func setupPlayerToPlay() -> AVPlayerViewController {
    
    let pvc = PlayerViewControllerObservable.pvc
    guard let _ = pvc.videoController.player else { return pvc.videoController }
    
    let player = pvc.videoController.player
    player?.replaceCurrentItem(with: nil)
    pvc.videoController = AVPlayerViewController()
    pvc.videoController.player = player
    pvc.videoController.player?.externalPlaybackVideoGravity = .resizeAspectFill
    pvc.videoController.player?.preventsDisplaySleepDuringVideoPlayback = true
    pvc.videoController.player?.usesExternalPlaybackWhileExternalScreenIsActive = false
    pvc.videoController.player?.appliesMediaSelectionCriteriaAutomatically = true
    pvc.videoController.player?.preventsDisplaySleepDuringVideoPlayback = true
    pvc.videoController.player?.allowsExternalPlayback = true
    pvc.videoController.player?.currentItem?.automaticallyHandlesInterstitialEvents = true
    pvc.videoController.player?.currentItem?.seekingWaitsForVideoCompositionRendering = true
    pvc.videoController.player?.currentItem?.appliesPerFrameHDRDisplayMetadata = true
    pvc.videoController.player?.currentItem?.preferredForwardBufferDuration = 30
    pvc.videoController.player?.currentItem?.automaticallyPreservesTimeOffsetFromLive = true
    pvc.videoController.player?.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
    pvc.videoController.player?.currentItem?.configuredTimeOffsetFromLive = .init(seconds: 30, preferredTimescale: 1200)
    pvc.videoController.player?.currentItem?.startsOnFirstEligibleVariant = true
    pvc.videoController.player?.currentItem?.variantPreferences = .scalabilityToLosslessAudio
    pvc.videoController.player?.automaticallyWaitsToMinimizeStalling = true
    return pvc.videoController
}

public class Coordinator: NSObject, AVPlayerViewControllerDelegate, UINavigationControllerDelegate {
    let po = PlayerObservable.plo
    
    public func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        po.fullscreen = true
    }
    
    public func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        po.fullscreen = false
    }
    
    public func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        po.pip = true
    }
    
    public func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        po.pip = false
    }
}



func setupRemoteTransportControls() {
    let pvc = PlayerViewControllerObservable.pvc
    
    guard let _ = pvc.videoController.player  else { return }
    
    
    let commandCenter = MPRemoteCommandCenter.shared()
    let seekDuration: Float64 = 10
    
    commandCenter.accessibilityActivate()
    
    commandCenter.playCommand.addTarget(handler: { (event) in
        pvc.videoController.player?.play()
        return MPRemoteCommandHandlerStatus.success}
    )
    
    commandCenter.pauseCommand.addTarget(handler: { (event) in
        pvc.videoController.player?.pause()
        return MPRemoteCommandHandlerStatus.success}
    )
    
    commandCenter.skipBackwardCommand.addTarget(handler: { (event) in
        skipBackward()
        return MPRemoteCommandHandlerStatus.success}
    )
    
    commandCenter.skipForwardCommand.addTarget(handler: { (event) in
        skipForward()
        return MPRemoteCommandHandlerStatus.success}
    )
    
    commandCenter.togglePlayPauseCommand.addTarget(handler: { (event) in
        pvc.videoController.player?.rate == 1 ?  pvc.videoController.player?.pause() :  pvc.videoController.player?.play()
        return MPRemoteCommandHandlerStatus.success}
    )
    
    func skipForward() {
        guard
            let player = pvc.videoController.player
        else {
            return
        }
        
        var playerCurrentTime = CMTimeGetSeconds( player.currentTime() )
        playerCurrentTime += seekDuration
        
        let time: CMTime = CMTimeMake(value: Int64(playerCurrentTime * 1000 as Float64), timescale: 1000)
        pvc.videoController.player?.seek(to: time)
    }
    
    func skipBackward() {
        guard
            let player = pvc.videoController.player
        else {
            return
        }
        
        var playerCurrentTime = CMTimeGetSeconds( player.currentTime() )
        playerCurrentTime -= seekDuration
        
        let time: CMTime = CMTimeMake(value: Int64(playerCurrentTime * 1000 as Float64), timescale: 1000)
        pvc.videoController.player?.seek(to: time)
    }
}
