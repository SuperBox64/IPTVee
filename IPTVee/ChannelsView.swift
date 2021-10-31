//
//  ChannelsView.swift
//  IPTVee
//
//  Created by Todd Bruss on 10/1/21.
//

import SwiftUI
import iptvKit
import AVKit

struct ChannelsView: View {
    
    internal init(categoryID: String, categoryName: String) {
        self.categoryID = categoryID
        self.categoryName = categoryName
    }
    
    let categoryID: String
    let categoryName: String
    @State var searchText: String = ""
    @State var selectedChannel: String?
    @State var isActive: Bool = false
    @State var selectedItem: Int?
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var lgo = LoginObservable.shared
    @ObservedObject var cha = ChannelsObservable.shared

    //It's a long one line but it works
    var channelSearchResults: [iptvChannel] {
        (cha.chan.filter({ $0.categoryID == categoryID })
            .filter({"\($0.num)\($0.name)\($0.nowPlaying)"
            .lowercased()
            .contains(searchText.lowercased()) || searchText.isEmpty}))
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            
            Form {
                    
                Section(header: Text("CHANNELS")) {
                    ForEach(Array(channelSearchResults),id: \.id) { ch in
    
                       HStack {

                            HStack {
                                Text("\(ch.num)")
                                    .fontWeight(.medium)
                                    .font(.system(size: 24, design: .monospaced))
                                    .frame(minWidth: 40, idealWidth: 80, alignment: .trailing)

                                
                            }
                            
                            VStack (alignment: .leading, spacing: 0) {
                                Text(ch.name)
                                    .font(.system(size: 16, design: .default))
                                    .fontWeight(.regular)
                                
                                if !ch.nowPlaying.isEmpty {
                                    Text(ch.nowPlaying)
                                        .font(.system(size: 14, design: .default))
                                        .fontWeight(.light)
                                }
                            }
                            .padding(.leading, 7.5)
                            .frame(alignment: .center)
                            
                        }
                        .listRowBackground(self.selectedItem == ch.streamID ? Color("iptvTableViewSelection") : Color("iptvTableViewBackground"))
                        .onTapGesture { self.selectedItem = ch.streamID; AirPlayr(streamId: ch.streamID) }

                    }

                }
            }
            
        }
    }
    
    func performMagicTapStop() {
        plo.videoController.player?.pause()
    }
    
    func AirPlayr(streamId: Int) {
        
        if streamId != plo.previousStreamID  {
            plo.previousStreamID = streamId

           plo.videoController.player?.replaceCurrentItem(with: nil)
         //  plo.videoController.delegate = context.coordinator
         //  plo.videoController.requiresLinearPlayback = false
        //   plo.videoController.canStartPictureInPictureAutomaticallyFromInline = true
        //    plo.videoController.accessibilityPerformMagicTap()
           let good: String = lgo.username
           let time: String = lgo.password
           let todd: String = lgo.config?.serverInfo.url ?? "primestreams.tv"
           let boss: String = lgo.config?.serverInfo.port ?? "826"
           
           let primaryUrl = URL(string:"https://starplayrx.com:8888/\(todd)/\(boss)/\(good)/\(time)/\(streamId)/hlsx.m3u8")
            let backupUrl = URL(string:"http://localhost:\(hlsxPort)/\(plo.streamID)/hlsx.m3u8")
           let airplayUrl = URL(string:"http://\(todd):\(boss)/live/\(good)/\(time)/\(streamId).m3u8")
           
           guard
               let primaryUrl = primaryUrl,
               let backupUrl = backupUrl,
               let airplayUrl = airplayUrl
                   
           else { return }
                       
           func playUrl(_ streamUrl: URL) {
               DispatchQueue.main.async {
                   let options = [AVURLAssetPreferPreciseDurationAndTimingKey : true, AVURLAssetAllowsCellularAccessKey : true, AVURLAssetAllowsExpensiveNetworkAccessKey : true, AVURLAssetAllowsConstrainedNetworkAccessKey : true, AVURLAssetReferenceRestrictionsKey: true ]
                   
                   let playNowUrl = avSession.currentRoute.outputs.first?.portType == .airPlay || plo.videoController.player!.isExternalPlaybackActive ? airplayUrl : streamUrl
               
                   plo.streamID = streamId
                   
                   let asset = AVURLAsset.init(url: playNowUrl, options:options)
                   let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["duration"])
                   plo.videoController.player?.replaceCurrentItem(with: playerItem)
                   plo.videoController.player?.playImmediately(atRate: 1.0)
               }
           }
           
           func starPlayrHLSx() {
               rest.textAsync(url: "https://starplayrx.com:8888/eHRybS5tM3U4") { hlsxm3u8 in
                   let decodedString = (hlsxm3u8?.base64Decoded ?? "This is a really bad error 1.")
                   primaryUrl.absoluteString.contains(decodedString) ? playUrl(primaryUrl) : localHLSx()
               }
           }
           
           func localHLSx() {
               rest.textAsync(url: "http://localhost:\(hlsxPort)/eHRybS5tM3U4/") { hlsxm3u8 in
                   let decodedString = (hlsxm3u8?.base64Decoded ?? "This is a really bad error 2.")
                   backupUrl.absoluteString.contains(decodedString) ? playUrl(backupUrl) : playUrl(airplayUrl)
               }
           }
           
           starPlayrHLSx()
           
           plo.videoController.player?.externalPlaybackVideoGravity = .resizeAspectFill
           plo.videoController.player?.preventsDisplaySleepDuringVideoPlayback = true
           plo.videoController.player?.usesExternalPlaybackWhileExternalScreenIsActive = true
           plo.videoController.player?.appliesMediaSelectionCriteriaAutomatically = true
           plo.videoController.player?.preventsDisplaySleepDuringVideoPlayback = true
           plo.videoController.player?.allowsExternalPlayback = true
           plo.videoController.player?.currentItem?.automaticallyHandlesInterstitialEvents = true
           plo.videoController.player?.currentItem?.seekingWaitsForVideoCompositionRendering = true
           plo.videoController.player?.currentItem?.appliesPerFrameHDRDisplayMetadata = true
           plo.videoController.player?.currentItem?.preferredForwardBufferDuration = 60
           plo.videoController.player?.currentItem?.automaticallyPreservesTimeOffsetFromLive = true
           plo.videoController.player?.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
           plo.videoController.player?.currentItem?.configuredTimeOffsetFromLive = .init(seconds: 60, preferredTimescale: 600)
           plo.videoController.player?.currentItem?.startsOnFirstEligibleVariant = true
           plo.videoController.player?.currentItem?.variantPreferences = .scalabilityToLosslessAudio
            
        //    if SettingsObservable.shared. {
          //      plo.videoController.player?.pause()
            //}
            
           plo.videoController.player?.automaticallyWaitsToMinimizeStalling = true
           plo.videoController.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
           plo.videoController.showsPlaybackControls = true
       }
    }

}

