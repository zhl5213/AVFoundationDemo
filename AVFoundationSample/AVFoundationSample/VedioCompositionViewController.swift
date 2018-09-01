
//
//  VedioCompositionViewController.swift
//  AVFoundationSample
//
//  Created by 朱慧林 on 2018/8/19.
//  Copyright © 2018年 朱慧林. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MBProgressHUD

let keywindow:UIWindow = (UIApplication.shared.delegate?.window!)!

class VedioCompositionViewController: UIViewController {
    
   typealias avAssetLoadCompleteHandler = (_ avAsset:AVAsset)->()

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var centerPlayButton: UIButton!
    
    let avAsset1 = AVAsset.init(url: Bundle.main.url(forResource: "TestVedio", withExtension: "mp4")!)
    let avAsset2 = AVAsset.init(url: Bundle.main.url(forResource: "TestVedio2", withExtension: "mp4")!)
    
    @objc let player = AVPlayer.init()
    @objc var playItem:AVPlayerItem? {
        didSet{
            self.player.replaceCurrentItem(with: self.playItem)
        }
    }
    
    lazy var playerLayer:AVPlayerLayer = {
        let layer = AVPlayerLayer.init(player: player)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.frame = playerView.bounds
        return layer
    }()
    
    let loadKeys = ["playable",
                    "hasProtectedContent",
                    "availableMetadataFormats"]
    
    var vedioDuration:CMTime?
    
    
    //    MARK: - viewController lifeCycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.layer.addSublayer(playerLayer)
        bringSubviewsToFront()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBProgressHUD.showAdded(to: keywindow, animated: true)
        loadAssetAsynchronous(with: avAsset1) { [unowned self] (avAsset1) in
            self.loadAssetAsynchronous(with: self.avAsset2, completeHandler: { (avAsset2) in
                self.startRecompositeAvasset(with:avAsset1,and:self.avAsset2)
            })
        }
    }
    
    func bringSubviewsToFront() -> () {
        view.bringSubview(toFront: centerPlayButton)
    }
    
    func loadAssetAsynchronous(with avAsset:AVAsset,completeHandler:@escaping avAssetLoadCompleteHandler) -> () {
        
        avAsset.loadValuesAsynchronously(forKeys: loadKeys) {[unowned self] in
            var error:NSError? = nil
            
            for key in self.loadKeys {
                print("----loadValuesAsynchronously key =\(key)\n\n")
                if avAsset.statusOfValue(forKey: key, error: &error) == .failed {
                    return
                }
            }
            
            if avAsset.isPlayable == false || avAsset.hasProtectedContent {
                return
            }
            print("loadAssetAsynchronous success\n")
            completeHandler(avAsset)
        }
    }
    
    func startRecompositeAvasset(with avAsset1:AVAsset,and avAsset2:AVAsset) -> () {
        
        let mutableCompostion = AVMutableComposition.init()
        let mutableVedioCompositionTrack = mutableCompostion.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mutableAudioCompositionTrack = mutableCompostion.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let firstAssetVedioTrack = avAsset1.tracks(withMediaType: AVMediaType.video)[0]
        let secondAssetVedioTrack = avAsset2.tracks(withMediaType: AVMediaType.video)[0]
        let firstAssetAudioTrack = avAsset1.tracks(withMediaType: AVMediaType.audio)[0]
        let secondAssetAudioTrack = avAsset2.tracks(withMediaType: AVMediaType.audio)[0]
        
        do {
            
            try mutableVedioCompositionTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAssetVedioTrack.timeRange.duration), of: firstAssetVedioTrack, at: kCMTimeZero)
           try mutableVedioCompositionTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAssetVedioTrack.timeRange.duration), of: secondAssetVedioTrack, at: firstAssetVedioTrack.timeRange.duration)
            try mutableAudioCompositionTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAssetAudioTrack.timeRange.duration), of: firstAssetAudioTrack, at: kCMTimeZero)
            try mutableAudioCompositionTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAssetAudioTrack.timeRange.duration), of: secondAssetAudioTrack, at: firstAssetAudioTrack.timeRange.duration)

        } catch  {
            print("error=\(error)")
        }
        
        
        let firstVedioCompositionInstruction = AVMutableVideoCompositionInstruction.init()
        firstVedioCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAssetVedioTrack.timeRange.duration)
        let firstVedioLayerCompositionInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: firstAssetVedioTrack)
        firstVedioLayerCompositionInstruction.setOpacityRamp(fromStartOpacity: 0.3, toEndOpacity: 1, timeRange: CMTimeRangeMake(kCMTimeZero, firstAssetVedioTrack.timeRange.duration))
        firstVedioLayerCompositionInstruction.setTransformRamp(fromStart: CGAffineTransform.init(rotationAngle: CGFloat(90.0/360*CGFloat.pi)), toEnd: CGAffineTransform.identity, timeRange: CMTimeRangeMake(kCMTimeZero, firstAssetVedioTrack.timeRange.duration))
        firstVedioCompositionInstruction.layerInstructions = [firstVedioLayerCompositionInstruction]
        
        let secondVedioCompositionInstruction = AVMutableVideoCompositionInstruction.init()
        secondVedioCompositionInstruction.timeRange = CMTimeRangeMake(firstAssetVedioTrack.timeRange.duration, secondAssetVedioTrack.timeRange.duration + firstAssetVedioTrack.timeRange.duration)
        let secondVedioLayerCompositionInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: secondAssetVedioTrack)
        secondVedioLayerCompositionInstruction.setOpacityRamp(fromStartOpacity: 0.3, toEndOpacity: 1, timeRange: secondAssetVedioTrack.timeRange)
        secondVedioLayerCompositionInstruction.setTransformRamp(fromStart: CGAffineTransform.init(rotationAngle: CGFloat(45/360*CGFloat.pi)), toEnd: CGAffineTransform.identity, timeRange: secondAssetVedioTrack.timeRange)
        
        secondVedioCompositionInstruction.layerInstructions = [secondVedioLayerCompositionInstruction]
        
        
        let mutableVedioComposition = AVMutableVideoComposition.init()
        mutableVedioComposition.instructions = [firstVedioCompositionInstruction,secondVedioCompositionInstruction]
        mutableVedioComposition.renderSize = CGSize.init(width: 480, height: 960)
        mutableVedioComposition.frameDuration = CMTimeMake(1, 30)
        
        
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
//        let vedioName = dateFormatter.string(from: Date.init(timeIntervalSinceNow: 0) as Date)
        
        let url = URL.init(fileURLWithPath:NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]).appendingPathComponent("vedio", isDirectory: false).appendingPathExtension("mp4")
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                print(" url = \(url) file exist")
            } catch {
                print("removeItem fail ,error=\(error)")
            }
        }
        
        let avAssertExporter = AVAssetExportSession.init(asset: mutableCompostion, presetName: AVAssetExportPresetMediumQuality)
        avAssertExporter?.outputURL = url
        avAssertExporter?.outputFileType = AVFileType.m4v
        avAssertExporter?.videoComposition = mutableVedioComposition
        
        avAssertExporter?.exportAsynchronously(completionHandler: {
            [unowned self] in
            
            defer {
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: keywindow, animated: true)
                }
            }
            
            if avAssertExporter?.status == AVAssetExportSessionStatus.completed {
                print("avAssertExporter completed")
                
                let compositionAVasset = AVAsset.init(url: (avAssertExporter?.outputURL)!)
                
                self.loadAssetAsynchronous(with: compositionAVasset, completeHandler: { [unowned self] (avasset) in
                    
                    self.playItem = AVPlayerItem.init(asset: avasset)
                    DispatchQueue.main.async {
                        self.centerPlayButton.isEnabled = true
                    }
                })
                
               if PHPhotoLibrary.authorizationStatus() == .authorized {
                 self.writeAssetToPhotosLibrary(at:(avAssertExporter?.outputURL)!)
               } else {
                PHPhotoLibrary.requestAuthorization({ (status) in
                    if status == .authorized {
                        self.writeAssetToPhotosLibrary(at:(avAssertExporter?.outputURL)!)
                    }else{
                        print("photos requestAuthorization fail")
                    }
                })
            }
        } else  if avAssertExporter?.status == AVAssetExportSessionStatus.failed {
                print("avAssertExporter failed ,error = \(String(describing: avAssertExporter?.error))")
            }
        })
        
    }
    
    
    func writeAssetToPhotosLibrary(at url:URL) -> () {
        
        DispatchQueue.main.async(execute: {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL:url)
            }, completionHandler: { (success, error) in
                if success && error == nil {
                    print("assert export into Photo library success")
                }else{
                    print("assert export into Photo library fail" )
                }
            }
            )
        }
        )
    }
    
    @IBAction func centerButtonIsTapped(_ sender: Any) {
        
        if player.rate == 0 {
            player.play()
        }else{
            player.pause()
        }
        
    }
    
    

}
