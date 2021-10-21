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
            Form {
                
                Section(header: Text("CHANNELS")) {
                    ForEach(Array(channelSearchResults),id: \.streamID) { ch in
                        let channelItem = "\(ch.num) \(ch.name)"
                        let url = URL(string:"http://\(lgo.url):\(lgo.port)/live/\(lgo.username)/\(lgo.password)/\(ch.streamID).m3u8")
                        
                            NavigationLink(channelItem, destination: PlayerView(url: url, channelName: ch.name, streamID: String(ch.streamID), imageUrl: ch.streamIcon ), tag: ch.streamID, selection: self.$selectedItem)
                            .listRowBackground(self.selectedItem == ch.streamID || (plo.previousStreamID == ch.streamID && self.selectedItem == nil) ? Color("iptvTableViewSelection") : Color("iptvTableViewBackground"))
                       
                     
                        
                        //MARK: - Todo Add Channel Logos { create backend code, and it download as a data file with bytes or SHA256 checksum }
                        //MARK: - Todo Electronic Program Guide, EPG -> Now Playing { add to filter }
                    }
                }
            }
            .accessibilityAction(.magicTap, {performMagicTapStop()})
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(categoryName)
            .frame(width: geometry.size.width)
            .onAppear {
                if plo.pip {
                    plo.fullscreen = false
                } else {
                    plo.miniEpg = []
                    plo.fullscreen = false
                }
                
            }.onDisappear{
                
                if selectedItem != nil {
                    plo.previousStreamID = selectedItem
                } else {
                    selectedItem = plo.previousStreamID
                }
                
            }
            
            .onReceive(epgTimer) { _ in
                if plo.videoController.player?.rate == 1 {
                    let min = Calendar.current.component(.minute, from: Date())
                    min % 6 == 0 || min % 6 == 3 ? getShortEpg(streamId: plo.streamID, channelName: plo.channelName, imageURL: plo.imageURL) : ()
                }
            }
            
            
            if #available(iOS 15.0, *) {
                #if !targetEnvironment(macCatalyst)
                Text("")
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Channels")
                #endif
            }
            
            
            
        }
        
        
    }
    
    
    
    
    func performMagicTapStop() {
        plo.videoController.player?.pause()
    }
}
