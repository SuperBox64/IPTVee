//
//  iOS.swift
//  IPTVee
//
//  Created by M1 on 11/5/21.
//

import Foundation
import UIKit
import AVKit

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
    
    UIGraphicsBeginImageContextWithOptions( targetSize, false, 1.0)
    
    image.draw(in: rect)
    
    if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
        UIGraphicsEndImageContext()
        return newImage
    }
    
    return UIImage()
}

public func setnowPlayingInfo(channelName:String, image: UIImage?) {
    /*   let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
     var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
     
     if let image = image {
     let img = image.squareMe()
     
     let artwork = MPMediaItemArtwork(boundsSize: img.size, requestHandler: {  (_) -> UIImage in
     return img
     })
     
     nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
     } else {
     nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
     }
     
     let title = PlayerObservable.plo.miniEpg.first?.title.base64Decoded ?? "IPTvee"
     nowPlayingInfo[MPMediaItemPropertyTitle] = channelName
     nowPlayingInfo[MPMediaItemPropertyArtist] = title
     nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "IPTVee"
     nowPlayingInfo[MPMediaItemPropertyMediaType] = 2
     nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = 2
     nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
     nowPlayingInfo[MPMediaItemPropertyAlbumTitle] =  PlayerObservable.plo.miniEpg.first?.start.toDate()?.toString()
     nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
     
     if PlayerObservable.pvc.videoController.player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
     nowPlayingInfoCenter.playbackState = .paused
     } else {
     nowPlayingInfoCenter.playbackState = PlayerObservable.pvc.videoController.player?.timeControlStatus == .playing  ? .playing : .stopped
     }
     
     nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
     */
}

public extension UIDevice {
    var hasNotch: Bool {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return true
        }
        return scene.keyWindow?.safeAreaInsets.bottom ?? 0 > 0
    }
}

extension UIImage {
    func squareMe() -> UIImage {
        var squareImage = self
        let maxSize = max(self.size.height, self.size.width)
        let squareSize = CGSize(width: maxSize, height: maxSize)
        
        let dx = CGFloat((maxSize - self.size.width) / 2)
        let dy = CGFloat((maxSize - self.size.height) / 2)
        
        UIGraphicsBeginImageContext(squareSize)
        var rect = CGRect(x: 0, y: 0, width: maxSize, height: maxSize)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.systemGray6.cgColor)
            context.fill(rect)
            
            rect = rect.insetBy(dx: dx, dy: dy)
            self.draw(in: rect, blendMode: .normal, alpha: 1.0)
            
            if let img = UIGraphicsGetImageFromCurrentImageContext() {
                squareImage = img
            }
            UIGraphicsEndImageContext()
            
        }
        return squareImage
    }
}

//MARK: - 4
class PlayerViewControllerObservable: ObservableObject {
    static public var pvc = PlayerViewControllerObservable()
    @Published public var videoController: AVPlayerViewController = AVPlayerViewController()
}
