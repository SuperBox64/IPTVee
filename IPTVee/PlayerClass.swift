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
        
        let airplayUrl = URL(string:"http://\(todd):\(boss)/live/\(good)/\(time)/\(streamId).m3u8")
        guard
            let airplayUrl
        else { return }
        
        func playUrl(_ streamUrl: URL) {
            DispatchQueue.main.async {
                let options = [AVURLAssetPreferPreciseDurationAndTimingKey : true, AVURLAssetAllowsCellularAccessKey : true, AVURLAssetAllowsExpensiveNetworkAccessKey : true, AVURLAssetAllowsConstrainedNetworkAccessKey : true, AVURLAssetReferenceRestrictionsKey: true ]
                
                guard let player = self.pvc.videoController.player else { return }
                self.plo.streamID = streamId
                let asset = AVURLAsset.init(url: airplayUrl, options:options)
                let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["duration"])
                player.replaceCurrentItem(with: playerItem)
                player.play()
            }
        }
        playUrl(airplayUrl)
    }
}
