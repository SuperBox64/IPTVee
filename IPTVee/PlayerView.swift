import SwiftUI
import AVKit
import iptvKit
import Combine

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
    @State var videoStarted: Bool = false
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
            
            if pvc.isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.75)
                    .offset(y:10)
                    .onReceive(Timer.publish(every: 2.2, on: .main, in: .common).autoconnect()) { _ in
                        pvc.isBuffering = pvc.videoController.player?.rate != 1
                    }
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
                            .accessibilityLabel(favorites.contains(streamID) ? "Remove from Favorites" : "Add to Favorites")
                            .accessibilityHint(favorites.contains(streamID) ? "Double tap to remove \(name) from favorites" : "Double tap to add \(name) to favorites")
                    }
                }
            }
            .alert("Playback Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification)) { _ in
                errorMessage = "Channel '\(name)' failed to play. The stream may be offline or unavailable."
                showErrorAlert = true
            }
            .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.playbackStalledNotification)) { _ in
                errorMessage = "Channel '\(name)' playback stalled. This could be due to network issues or the stream being unavailable."
                showErrorAlert = true
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
