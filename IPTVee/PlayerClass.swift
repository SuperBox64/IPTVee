//
//  PlayerClass.swift
//  IPTVee
//
//  Created by M1 on 11/2/21.
//

import Foundation
import iptvKit
import AVKit

public class Player: NSObject {
    
    var plo = PlayerObservable.plo
    var pvc = PlayerViewControllerObservable.pvc
    var lgo = LoginObservable.shared
    var cha = ChannelsObservable.shared

    static public let iptv = Player()
    public func Action(streamId: Int, channelName: String, imageURL: String) {
        plo.streamID = streamId
        nowPlaying(channelName: channelName, streamId: streamId, imageURL: imageURL)
        airPlayr(streamId: streamId)
    }
    
    func nowPlaying(channelName: String, streamId: Int, imageURL: String) {
        plo.streamID = streamId
        plo.imageURL = imageURL
        //getShortEpg(streamId: streamId, channelName: channelName, imageURL: imageURL)
    }
    
    func airPlayr(streamId: Int) {
        
        let good: String = lgo.username
        let time: String = lgo.password
        let todd: String = lgo.config?.serverInfo.url ?? "primestreams.tv"
        let boss: String = lgo.config?.serverInfo.port ?? "826"
        
        //let primaryUrl = URL(string:"https://starplayrx.com:8888/\(todd)/\(boss)/\(good)/\(time)/\(streamId)/hlsx.m3u8")
        //let backupUrl = URL(string:"http://localhost:\(hlsxPort)/\(plo.streamID)/hlsx.m3u8")
        let airplayUrl = URL(string:"http://\(todd):\(boss)/live/\(good)/\(time)/\(streamId).m3u8")
        //print("http://\(todd):\(boss)/live/\(good)/\(time)/\(streamId).m3u8")
        guard
            //let primaryUrl = primaryUrl,
            //let backupUrl = backupUrl,
            let airplayUrl = airplayUrl
                
        else { return }
    
        func playUrl(_ streamUrl: URL) {
            DispatchQueue.main.async {
                let options = [AVURLAssetPreferPreciseDurationAndTimingKey : true, AVURLAssetAllowsCellularAccessKey : true, AVURLAssetAllowsExpensiveNetworkAccessKey : true, AVURLAssetAllowsConstrainedNetworkAccessKey : true, AVURLAssetReferenceRestrictionsKey: true ]
                
                guard let player = self.pvc.videoController.player else { return }
                //let playNowUrl = avSession.currentRoute.outputs.first?.portType == .airPlay || player.isExternalPlaybackActive ? airplayUrl : streamUrl
                self.plo.streamID = streamId
                let asset = AVURLAsset.init(url: airplayUrl, options:options)
                let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["duration"])
                player.replaceCurrentItem(with: playerItem)
                player.play()
            }
        }
        
//        func starPlayrHLSx() {
//            rest.textAsync(url: "https://starplayrx.com:8888/eHRybS5tM3U4") { hlsxm3u8 in
//                let decodedString = (hlsxm3u8?.base64Decoded ?? "This is a really bad error 1.")
//                primaryUrl.absoluteString.contains(decodedString) ? playUrl(primaryUrl) : localHLSx()
//            }
//        }
        
//        func localHLSx() {
//            rest.textAsync(url: "http://localhost:\(hlsxPort)/eHRybS5tM3U4/") { hlsxm3u8 in
//                let decodedString = (hlsxm3u8?.base64Decoded ?? "This is a really bad error 2.")
//                backupUrl.absoluteString.contains(decodedString) ? playUrl(backupUrl) : playUrl(airplayUrl)
//            }
//        }
        
        playUrl(airplayUrl)
        //localHLSx()
    }
}
