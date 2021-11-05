import SwiftUI
import AVKit
import iptvKit

struct PlayerView: View {
    @State private var showDetails = false
    @State private var orientation = UIDeviceOrientation.unknown
    
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var pvc = PlayerViewControllerObservable.pvc

    @State var isPortrait: Bool = true
    
    var isPortraitFallback: Bool {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return true
        }
        return scene.interfaceOrientation.isPortrait
    }
    
    let avPlayerView = AVPlayerView()
    
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    fileprivate func getOrientation() {
        if UIDevice.current.orientation.isPortrait { isPortrait = true; return}
        if UIDevice.current.orientation.isLandscape { isPortrait = false; return}
        isPortrait = isPortraitFallback
    }
    
    var body: some View {
        Group {
            
            GeometryReader { geometry in
                Form{}
                
                VStack {
                    
                    if isPad {
                        avPlayerView
                            .frame(width: geometry.size.width, height: geometry.size.width * 0.5625, alignment: .top)
                            .transition(.opacity)
                    } else {
                        avPlayerView
                            .frame(width: isPortrait ? geometry.size.width : .infinity, height: isPortrait ? geometry.size.width * 0.5625 : .infinity, alignment: .top)
                            .transition(.opacity)
                    }
                   
                    if isPortrait {
                        NowPlayingView(isPortrait: true)
                            .refreshable {
                                getShortEpg(streamId: plo.streamID, channelName: plo.channelName, imageURL: plo.imageURL)
                            }
                    } else if isPad {
                        NowPlayingView(isPortrait: false)
                            .refreshable {
                                getShortEpg(streamId: plo.streamID, channelName: plo.channelName, imageURL: plo.imageURL)
                            }
                    }
                    
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Group {
                            VStack {
                                if !isPhone, let desc = plo.miniEpg.first?.title.base64Decoded, desc.count > 3 {
                                        Text("\(plo.channelName)")
                                            .fontWeight(.bold)
                                            Text("\(desc)")
                                                .fontWeight(.regular)
                                } else {
                                    Text("\(plo.channelName)")
                                        .fontWeight(.bold)
                                    
                                    if !isPhone {
                                        Text("")
                                            .fontWeight(.regular)
                                    }
                                }
                            }
                            .frame(alignment: .leading)
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 320, alignment: .center)
                            .font(.body)
                        }
                        .padding(.top, 0)
                    }
                }
                .onAppear{getOrientation()}
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                    getOrientation()
                }
            }
        }
        .padding(.top, 0)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("")
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
