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
    @State var postSelection: Int?

    @ObservedObject var plo = PlayerObservable.plo
    let srv = LoginObservable.shared.config!.serverInfo
    let usr = LoginObservable.shared.config!.userInfo
    
    //It's a long one line but it works
    var channelSearchResults: [iptvChannel] {
        chan.filter({ $0.categoryID == categoryID })
            .filter({"\($0.num)\($0.name)"
            .lowercased()
                .contains(searchText.lowercased()) || searchText.isEmpty})
    }
    
    let epgTimer = Timer.publish(every: 60, on: .current, in: .default).autoconnect()
    
    var body: some View {
        
        GeometryReader { geometry in
            List {
                
                Section(header: Text("CHANNELS")) {
                    ForEach(Array(channelSearchResults),id: \.streamID) { ch in
                        let channelItem = "\(ch.num) \(ch.name)"
                        
                        let url = URL(string:"http://\(srv.url):\(srv.port)/live/\(usr.username)/\(usr.password)/\(ch.streamID).m3u8")
                        NavigationLink(channelItem, destination: PlayerView(url: url!, channelName: ch.name, streamID: String(ch.streamID), imageUrl: ch.streamIcon ), tag: ch.streamID, selection: self.$selectedItem)
                        
                            .listRowBackground(self.selectedItem == ch.streamID || self.postSelection == ch.streamID ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                        //MARK: - Todo Add Channel Logos { create backend code, and it download as a data file with bytes or SHA256 checksum }
                        //MARK: - Todo Electronic Program Guide, EPG -> Now Playing { add to filter }
                        /*NavigationLink(channelItem, destination: PlayerView(
                         channelName: ch.name, streamId: String(ch.streamID), imageUrl: ch.streamIcon, playerView: AVPlayerView(streamId: String(ch.streamID)) ))*/
                    }
                }
            }
            .accessibilityAction(.magicTap, {performMagicTapStop()})
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(categoryName)
            .frame(width: geometry.size.width)
            .toolbar {
                /*ToolbarItemGroup(placement: .bottomBar) {
                 Text(" ")
                 }*/
            }
            .onAppear {

                if plo.pip {
                    plo.fullscreen = false
                } else {
                    plo.miniEpg = []
                    plo.pip = false
                    plo.fullscreen = false
                    plo.streamID = ""
                    plo.channelName = ""
                    plo.imageURL = ""
                    setnowPlayingInfo(channelName: plo.channelName, image: nil)
                    //plo.videoController.player?.volume = 0
                    //plo.videoController.player?.pause()
                    //plo.videoController = AVPlayerViewController()
                    //plo.videoController.player = AVPlayer()
                }
                
            }.onDisappear{
                postSelection = selectedItem
                selectedItem = nil
            }
            
            .onReceive(epgTimer) { _ in
                if plo.videoController.player?.rate == 1 {
                    let min = Calendar.current.component(.minute, from: Date())
                    min % 6 == 0 || min % 6 == 3 ? getShortEpg(streamId: plo.streamID, channelName: plo.channelName, imageURL: plo.imageURL) : ()
                }
            }
            
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                Text("")
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Channels")
            }
            
            
        }
    }
    

    
    func performMagicTapStop() {
        plo.videoController.player?.pause()
    }
}
