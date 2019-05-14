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

class VedioPlayController: UIViewController {
    
    @IBOutlet weak var centerPlayButton: UIButton!
    @IBOutlet weak var currentPlayTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var playProgressSlider: UISlider!
    

//    let avAsset = AVAsset.init(url: Bundle.main.url(forResource: "TestVedio", withExtension: "mp4")!)
    let url:URL = URL.init(string: "https://vdse.bdstatic.com//0ce574b077682f7525f666fd9700f088?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//d2ed31351b2f374a92f888d18bfeaf7e7ad7594a2dc2a1e18ca5f91384a20a22")!

    lazy var avAsset = AVAsset.init(url: url)
    
    @objc let player = AVPlayer.init()
    
    @objc var playItem:AVPlayerItem? {
        didSet{
            self.player.replaceCurrentItem(with: self.playItem)
        }
    }
    
    let loadKeys = ["playable",
        "hasProtectedContent",
        "availableMetadataFormats"]
    
    var vedioDuration:CMTime?
    
    
    let keyPaths = [#keyPath(VedioPlayController.player.currentItem.duration),
        #keyPath(VedioPlayController.player.currentItem.status),
        #keyPath(VedioPlayController.player.currentItem.canPlayFastForward)]
    
    
    lazy var playerLayer:AVPlayerLayer = {
       let layer = AVPlayerLayer.init(player: player)
        layer.frame = view.bounds
       return layer
    }()

    var periodToken:Any?
    
    //    MARK:- viewController lifeCycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.addSublayer(playerLayer)
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.viewIsTapped(view:))))
        bringSubviewsToFront()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        obsererForProperty(isOpen: true)
        loadAssetAsynchronous()
        deviceOrientationChangeNoti(isOpen:true)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        obsererForProperty(isOpen: false)
        deviceOrientationChangeNoti(isOpen: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
    }
    
    
    func deviceOrientationChangeNoti(isOpen:Bool) -> () {
        if isOpen {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: self, queue: OperationQueue.main) { [unowned self](noti) in
                let oriention = UIDevice.current.orientation
                print(" UIDevice.current.orientation =\(oriention)")
                switch oriention {
                case .landscapeLeft,.landscapeRight:
                    self.rotatePlayer(isFullScrren:true)
                case .portrait,.portraitUpsideDown:
                    self.rotatePlayer(isFullScrren:false)
                default :
                    self.rotatePlayer(isFullScrren:false)
                }
            }
        } else {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        }
    }
    
    func rotatePlayer(isFullScrren:Bool) -> () {
        
//        if isFullScrren {
//
//            let height = UIScreen.main.bounds.width
//            let width = UIScreen.main.bounds.height
//            let frame = CGRect(x: (height - width)/2, y: (width - height)/2, width: width, height: height)
//            UIView.animate(withDuration: 0.3) {
//
//            }
//        } else {
//
//        }
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
                print("----loadValuesAsynchronously key =\(key)\n\n")

                if self.avAsset.statusOfValue(forKey: key, error: &error) == .failed {
                    return
                }
            }
            
            if self.avAsset.isPlayable == false || self.avAsset.hasProtectedContent {
                return
            }
            
            let commonMetaData = self.avAsset.commonMetadata
            for data in commonMetaData {
                print("commonMetaData = \(data)\n")
            }
            
             let metaFomats = self.avAsset.availableMetadataFormats
            for fomat in metaFomats {
                let metaData = self.avAsset.metadata(forFormat: fomat)
                for data in metaData {
                    print("for metaFomats,data = \(data)\n")
                }
            }
            
            self.playItem = AVPlayerItem.init(asset: self.avAsset)
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &playerContext,
            keyPaths.contains(keyPath!)
            else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        print("==keyPath =\(String(describing: keyPath))\n,change=\(String(describing: change))\n")
       
        if keyPath == #keyPath(VedioPlayController.player.currentItem.status) {
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
        
        if keyPath ==  #keyPath(VedioPlayController.player.currentItem.duration) {
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
            sender.isHidden = true
        } else {
            player.pause()
        }
        
    }
    
    @objc func viewIsTapped(view:UIView) -> () {
        
        if centerPlayButton.isHidden {
            if player.rate == 0 {
                player.play()
            }else{
                player.pause()
                centerPlayButton.isHidden = false
            }
        }
    }
    
}



extension VedioPlayController {
    
    func transformSecondsToTimeFormat(_ seconds:Int) -> String {
        
        let hour = seconds/3600
        let minute = (seconds/60)%60
        let second = seconds%60
        return String(format: "%02d:%02d:%02d", hour,minute,second)
    }
    
}


