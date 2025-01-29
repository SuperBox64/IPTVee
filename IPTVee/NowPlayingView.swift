//
//  NowPlayingView.swift
//  IPTVee
//
//  Created by M1 on 11/4/21.
//

import SwiftUI
import iptvKit

extension Text {
    func SectionHeader(_ isMac: Bool = false) -> some View {
        self.offset(y: isMac ? 12 : 0)
            .foregroundColor(Color.secondary)
            .font(.system(size: isMac ? 14 : 17, weight: .bold))
    }
}

struct NowPlayingView: View {
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var cha = ChannelsObservable.shared
    
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    let epgChannelId: String?
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    @State var categoryName: String = ""
    
    var body: some View {
        VStack {
            Form {
                if let npl = cha.nowPlayingLive[epgChannelId ?? ""] {
                    Section(header: Text("Program Guide").SectionHeader()) {
                        ForEach(npl.prefix(4),id: \.id) { epg in
                            
                            HStack {
                                //epg.start.toDate()?.userTimeZone().toString()
                                Text(epg.start.toDate()?.toString() ?? "")
                                    .fontWeight(.semibold)
                                    .font(.system(size: 17.333, design: .default))
                                    .frame(minWidth: 82, alignment: .trailing)
                                    .multilineTextAlignment(.leading)
                                Text(epg.title)
                                    .fontWeight(.medium)
                                    .font(.system(size: 17.333, design: .default))
                                    .multilineTextAlignment(.leading)
                                    .padding(.leading, 5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .listRowSeparator(.visible)
                            .font(.callout)
                        }
                    }
                    
                    if let desc = npl.first?.desc, desc.count > 3, updatePortrait() {
                        Section(header: Text("Description").SectionHeader())  {
                            Text(desc)
                                .frame(minWidth: 80, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            
                        }
                    }
                } else {
                    Section(header: Text("Description").SectionHeader()) {
                        HStack {
                            Text(categoryName.deletingPrefix("USA ") + " ")
                                .font(.body)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(plo.channelName.deletingPrefix("USA "))
                                .font(.body)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}
