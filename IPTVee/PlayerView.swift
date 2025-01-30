import SwiftUI
import AVKit
import iptvKit
import Combine
import AVFoundation

struct PlayerView: View {
    @State private var showDetails = false
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var favorites: [Int] = UserDefaults.standard.array(forKey: "favoriteChannels") as? [Int] ?? []
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var pvc = PlayerViewControllerObservable.pvc
    
    @State var streamID: Int = 0
    @State var name: String = ""
    @State var streamIcon: String = ""
    @State var categoryName: String = ""
    @State var videoStarted: Bool = true
    @State var stopProgress: Bool = false
    @State var repeater: TimeInterval = 0.1

    let epgChannelId: String?
    
    var isPortraitFallback: Bool {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return true
        }
        return scene.interfaceOrientation.isPortrait
    }
    
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    @State var isPortrait: Bool = false
    
    private var playerContent: some View {
        let avPlayerView = AVPlayerView(streamID: streamID, name: name, streamIcon: streamIcon)
        
        return ZStack {
            if isPad || (isPhone && isPortrait) {
                avPlayerView
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.5625, alignment: .top)
                    .navigationBarHidden(false)
                    .padding(.top, isPhone ? 15 : 0)
            } else {
                avPlayerView
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .navigationBarHidden(true)
            }
            
            if !stopProgress {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.75)
                    .offset(y:10)
                
            }
            
        }
        
    }
    
    private var nowPlayingContent: some View {
        Group {
            if isPortrait || isPad {
                NowPlayingView(epgChannelId: epgChannelId, categoryName: categoryName)
                    .refreshable {
                        refreshNowPlayingEpg()
                    }
            }
        }
    }
    
    var body: some View {
        GeometryReader { _ in
            VStack {
                playerContent
                nowPlayingContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleFavorite) {
                        Image(systemName: favorites.contains(streamID) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 22))
                           
                    } 
                    .accessibilityLabel(favorites.contains(streamID) ? "Remove from Favorites" : "Add to Favorites")
                    .accessibilityHint(favorites.contains(streamID) ?
                                       "Double tap to remove \(name)" :
                                        "Double tap to add \(name)")
                }
            }
            .alert("\(name)", isPresented: $showErrorAlert) {
                
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onReceive(Timer.publish(every: repeater, on: .main, in: .common).autoconnect()) { _ in
                if pvc.videoController.player?.currentItem?.status == .readyToPlay {
                    stopProgress = true
                    repeater = 2.0
                    
                    if let tracks = pvc.videoController.player?.currentItem?.tracks {
                        var audioTrackFound: Bool = false
                        for track in tracks {
                            if track.assetTrack?.mediaType == .audio {
                                audioTrackFound = true
                            }
                        }
                        
                        if !audioTrackFound, !showErrorAlert && videoStarted {
                            AudioServicesPlaySystemSound(1125)
                            videoStarted.toggle()
                            stopProgress = true
                            errorMessage = "Stream is not valid. It's missing an audio track."
                            showErrorAlert = true
                        }
                    }
                }
                
                if let error = pvc.videoController.player?.currentItem?.error, !showErrorAlert && videoStarted {
                    AudioServicesPlaySystemSound(1125)
                    videoStarted.toggle()
                    stopProgress = true
                    errorMessage = "\(error.localizedDescription)"
                    showErrorAlert = true
                }
             
            }
            
            
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                isPortrait = updatePortrait()
            }
            .onAppear {
                isPortrait = updatePortrait()
                plo.channelName = name
                
            }
        }
    }
    
    func toggleFavorite() {
        if favorites.contains(streamID) {
            favorites.removeAll { $0 == streamID }
        } else {
            favorites.append(streamID)
        }
        UserDefaults.standard.set(favorites, forKey: "favoriteChannels")
        NotificationCenter.default.post(name: NSNotification.Name("FavoritesChanged"), object: nil)
    }
    
    func performMagicTap() {
        pvc.videoController.player?.rate == 1 ? pvc.videoController.player?.pause() : pvc.videoController.player?.play()
    }
    
    //Back burner
    func skipForward(_ videoController: AVPlayerViewController ) {
        let seekDuration: Double = 10
        videoController.player?.pause()
        
        guard
            let player = videoController.player
        else {
            return
        }
        
        var playerCurrentTime = CMTimeGetSeconds( player.currentTime() )
        playerCurrentTime += seekDuration
        
        let time: CMTime = CMTimeMake(value: Int64(playerCurrentTime * 1000 as Double), timescale: 1000)
        videoController.player?.seek(to: time)
        videoController.player?.play()
    }
    
    //Back burner
    func skipBackward(_ videoController: AVPlayerViewController ) {
        let seekDuration: Double = 10
        videoController.player?.pause()
        
        guard
            let player = videoController.player
        else {
            return
        }
        
        var playerCurrentTime = CMTimeGetSeconds( player.currentTime() )
        playerCurrentTime -= seekDuration
        
        let time: CMTime = CMTimeMake(value: Int64(playerCurrentTime * 1000 as Double), timescale: 1000)
        videoController.player?.seek(to: time)
        videoController.player?.play()
    }
}
