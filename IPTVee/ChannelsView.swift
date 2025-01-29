//
//  ChannelsView.swift
//  IPTVee
//
//  Created by Todd Bruss on 10/1/21.
//

import SwiftUI
import iptvKit
import AVKit

let epgLongTimer = Timer.publish(every: 60, on: .current, in: .default).autoconnect()

struct ChannelsView: View {
    
    internal init(categoryID: String, categoryName: String) {
        self.categoryID = categoryID
        self.categoryName = categoryName
    }
    
    let usa = "USA "
    let categoryID: String
    let categoryName: String
    @State var searchText: String = ""
    @State var selectedChannel: String?
    @State var isActive: Bool = false
    @State var selectedItem: String?
    @State var runningMan: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var lgo = LoginObservable.shared
    @ObservedObject var cha = ChannelsObservable.shared
    @ObservedObject var pvc = PlayerViewControllerObservable.pvc
    @Environment(\.presentationMode) var presentationMode
    @State private var favorites: [Int] = UserDefaults.standard.array(forKey: "favoriteChannels") as? [Int] ?? []
    @State private var forceUpdate: Bool = false
    
    var channelSearchResults: [iptvChannel] {
        var channels = cha.chan
        
        if categoryID == "favorites" {
            channels = channels.filter { favorites.contains($0.streamID) }
        } else {
            channels = channels.filter { $0.categoryID == categoryID }
        }
        
        return channels
            .filter{"\($0.num)\($0.name)\(cha.nowPlayingLive[$0.epgChannelID ?? ""]?.first?.title ?? "")"
                .lowercased()
                .contains(searchText.lowercased()) || searchText.isEmpty}
            .sorted{$0.num < $1.num}
    }
    
    @State var isShowingColumn = true
    var isPortrait: Bool {
        if UIDevice.current.orientation.isPortrait { return true}
        if UIDevice.current.orientation.isLandscape { return false}
        return isPortraitFallback
    }
    
    var isPortraitFallback: Bool {
        guard let scene =  (UIApplication.shared.connectedScenes.first as? UIWindowScene) else {
            return true
        }
        return scene.interfaceOrientation.isPortrait
    }
    
    var body: some View {
        Form {
            ForEach(Array(channelSearchResults), id: \.id) { ch in
                ChannelRowView(channel: ch, 
                               categoryName: categoryName, 
                               favorites: favorites, 
                               toggleFavorite: toggleFavorite)
            }
        }
        .padding(.bottom, 10)
        .padding(.leading, -40)
        .padding(.trailing, -30)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search \(categoryName)")
        .disableAutocorrection(true)
        .autocapitalization(.none)
        .onReceive(epgLongTimer) { _ in
            refreshNowPlayingEpg()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshNowPlayingEpgBytes()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FavoritesChanged"))) { _ in
            favorites = UserDefaults.standard.array(forKey: "favoriteChannels") as? [Int] ?? []
        }
        .refreshable {
            refreshNowPlayingEpgBytes()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(categoryName)
        .onAppear {
            plo.previousCategoryID = categoryID
            refreshNowPlayingEpgBytes()
            favorites = UserDefaults.standard.array(forKey: "favoriteChannels") as? [Int] ?? []
        }
    }
    
    func performMagicTapStop() {
        pvc.videoController.player?.pause()
    }
    
    func toggleFavorite(streamID: Int) {
        if favorites.contains(streamID) {
            favorites.removeAll { $0 == streamID }
        } else {
            favorites.append(streamID)
        }
        UserDefaults.standard.set(favorites, forKey: "favoriteChannels")
        NotificationCenter.default.post(name: NSNotification.Name("FavoritesChanged"), object: nil)
    }
}

// Break out the row into its own view to reduce complexity
struct ChannelRowView: View {
    let channel: iptvChannel
    let categoryName: String
    let favorites: [Int]
    let toggleFavorite: (Int) -> Void
    
    @ObservedObject var plo = PlayerObservable.plo
    
    var body: some View {
        HStack {
            NavigationLink(destination: PlayerView(streamID: channel.streamID, 
                                                   name: channel.name, 
                                                   streamIcon: channel.streamIcon, 
                                                   categoryName: categoryName, 
                                                   epgChannelId: channel.epgChannelID)) {
                ChannelContentView(channel: channel)
            }
            
            FavoriteButton(streamID: channel.streamID, 
                           favorites: favorites, 
                           toggleFavorite: toggleFavorite)
        }
        .listRowBackground(plo.previousStreamID == channel.streamID ? 
                           Color.accentColor : 
                            Color(UIColor.systemGray6))
    }
}

struct ChannelContentView: View {
    let channel: iptvChannel
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var cha = ChannelsObservable.shared
    let usa = "USA "
    
    var body: some View {
        HStack(spacing: 0) {
            // Channel Image and Number
            VStack(spacing: 0) {
                AsyncImage(url: URL(string: channel.streamIcon)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(5)
                    case .empty, .failure:
                        // Ensure the fallback app icon image is properly displayed
                        Image("IPTVeeLogo")
                            .resizable() // Make the fallback image resizable
                            .aspectRatio(contentMode: .fit) // Maintain aspect ratio(
                            .padding(5)
                    @unknown default:
                        Image("IPTVeeLogo")
                            .resizable() // Make the fallback image resizable
                            .aspectRatio(contentMode: .fit) // Maintain aspect ratio
                            .padding(5)
                    }
                }
                .frame(width: 80, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.85, green: 0.9, blue: 0.95).opacity(0.25))
                        .shadow(radius: 1)
                )
                
                
                Text(String(channel.num))
                    .fontWeight(.bold)
                    .font(.system(size: 14, design: .default))
                    .foregroundColor(plo.previousStreamID == channel.streamID ? .white : .primary)
            }
            .frame(width: 80, height: 60)
            .padding(.horizontal)
            
            // Channel Info
            ChannelInfoView(channel: channel)
        }
    }
}

struct ChannelInfoView: View {
    let channel: iptvChannel
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var cha = ChannelsObservable.shared
    let usa = "USA "
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(channel.name.deletingPrefix(usa))
                .font(.system(size: 19, design: .default))
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(plo.previousStreamID == channel.streamID ? .white : .primary)
            
            EPGInfoView(channel: channel)
        }
    }
}

struct EPGInfoView: View {
    let channel: iptvChannel
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var cha = ChannelsObservable.shared
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if let npl = cha.nowPlayingLive[channel.epgChannelID ?? ""]?.first,
               let start = npl.start.toDate()?.toString(),
               let stop = npl.stop.toDate()?.toString() {
                Text("\(start) — \(stop)\n\(npl.title)")
                    .font(.system(size: 18, design: .default))
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(plo.previousStreamID == channel.streamID ? .white : .primary)
            } else if let epgId = channel.epgChannelID {
                Text("\(epgId)")
                    .foregroundColor(plo.previousStreamID == channel.streamID ? .white : .orange)
                    .font(.system(size: 15, design: .default))
                    .fontWeight(.regular)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FavoriteButton: View {
    let streamID: Int
    let favorites: [Int]
    let toggleFavorite: (Int) -> Void
    
    var body: some View {
        Button(action: { toggleFavorite(streamID) }) {
            Image(systemName: favorites.contains(streamID) ? "star.fill" : "star")
                .foregroundColor(.yellow)
                .font(.system(size: 22))
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
