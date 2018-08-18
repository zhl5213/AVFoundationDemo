//
//  ViewController.swift
//  AVFoundationSample
//
//  Created by 朱慧林 on 2018/8/18.
//  Copyright © 2018年 朱慧林. All rights reserved.
//

import UIKit
import AVFoundation

private var playerContext = 0

class ViewController: UIViewController {
    
    @IBOutlet weak var centerPlayButton: UIButton!
    @IBOutlet weak var currentPlayTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var playProgressSlider: UISlider!
    

    let avAsset = AVAsset.init(url: Bundle.main.url(forResource: "ElephantSeals", withExtension: "mov")!)
    
    @objc let player = AVPlayer.init()
    @objc var playItem:AVPlayerItem? {
        didSet{
            self.player.replaceCurrentItem(with: self.playItem)
        }
    }
    
    let loadKeys = ["playable",
        "hasProtectedContent",
        "availableMetadataFormats"
        ]
    var vedioDuration:CMTime?
    
    
    let keyPaths = [#keyPath(ViewController.player.currentItem.duration),
        #keyPath(ViewController.player.currentItem.status),
        #keyPath(ViewController.player.currentItem.canPlayFastForward)]
    
    
    lazy var playerLayer:AVPlayerLayer = {
       let layer = AVPlayerLayer.init(player: player)
        layer.frame = view.bounds
       return layer
    }()

    var periodToken:Any?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.addSublayer(playerLayer)
        bringSubviewsToFront()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        obsererForProperty(isOpen: true)
        loadAssetAsynchronous()

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        obsererForProperty(isOpen: false)
    }
    
    
    func obsererForProperty(isOpen:Bool) -> () {
        for keyPath in keyPaths {
            if isOpen {
                addObserver(self, forKeyPath: keyPath, options: [.new,.initial], context: &playerContext)
            } else {
                removeObserver(self, forKeyPath: keyPath, context: &playerContext)
            }
        }
        
        if isOpen {
            
            periodToken = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.main, using: { [unowned self] (time) in
                
                self.playProgressSlider.value = Float(CMTimeGetSeconds(time)/CMTimeGetSeconds(self.vedioDuration!))
                self.currentPlayTimeLabel.text = self.transformSecondsToTimeFormat(Int(CMTimeGetSeconds(time)))
            })
            
        } else {
            if let trPeriodToken = periodToken {
                player.removeTimeObserver(trPeriodToken)
                periodToken = nil
            }
        }
    }
    

    func bringSubviewsToFront() -> () {
        view.bringSubview(toFront: centerPlayButton)
        view.bringSubview(toFront: currentPlayTimeLabel)
        view.bringSubview(toFront: totalTimeLabel)
        view.bringSubview(toFront: playProgressSlider)
    }
    
    
    func loadAssetAsynchronous() -> () {
        
        avAsset.loadValuesAsynchronously(forKeys: loadKeys) {[unowned self] in
            var error:NSError? = nil

            for key in self.loadKeys {
                print("loadValuesAsynchronously key =\(key)")

                if self.avAsset.statusOfValue(forKey: key, error: &error) == .failed {
                    return
                }
                
               
            }
            
            if self.avAsset.isPlayable == false || self.avAsset.hasProtectedContent {
                return
            }
            
             let metaFomats = self.avAsset.availableMetadataFormats
            for fomat in metaFomats {
                let metaData = self.avAsset.metadata(forFormat: fomat)
                for data in metaData {
                    print(data)
                }
            }
            
            self.playItem = AVPlayerItem.init(asset: self.avAsset)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &playerContext,
            keyPaths.contains(keyPath!)
            else {
            return
        }
        
        print("keyPath =\(String(describing: keyPath)),change=\(String(describing: change))")
       
        if keyPath == #keyPath(ViewController.player.currentItem.status) {
            let status:AVPlayerItemStatus
            
           if let numStatus = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                status = AVPlayerItemStatus.init(rawValue: numStatus.intValue)!
           }else {
             status = .unknown
          }

            if status == .readyToPlay {
                centerPlayButton.isEnabled = true
            }
        }
        
        if keyPath ==  #keyPath(ViewController.player.currentItem.duration) {
            let newDuration:CMTime
            
            if let trduration = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = trduration.timeValue
            }else{
                newDuration = kCMTimeZero
            }
            
            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            
            DispatchQueue.main.async {[unowned self] in
                self.totalTimeLabel.text = self.transformSecondsToTimeFormat(Int(newDurationSeconds))
            }
            vedioDuration = newDuration
        }
        
        
    }
    
    @IBAction func playButtonIsTapped(_ sender: UIButton) {
        
        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
        
    }
    
}

extension ViewController {
    
    func transformSecondsToTimeFormat(_ seconds:Int) -> String {
        
        let hour = seconds/3600
        let minute = (seconds/60)%60
        let second = seconds%60
        return String(format: "%02d:%02d:%02d", hour,minute,second)
    }
    
}


