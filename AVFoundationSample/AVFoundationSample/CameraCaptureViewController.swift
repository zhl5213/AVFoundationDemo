//
//  CameraCaptureViewController.swift
//  AVFoundationDemo
//
//  Created by 朱慧林 on 2018/8/15.
//  Copyright © 2018年 朱慧林. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MBProgressHUD
import OpenGLES

class CameraCaptureViewController: UIViewController {

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var replayButton: UIButton!
    @IBOutlet weak var recordTimeLabel: UILabel!
    @IBOutlet var playerView: UIView!
    
    var captureSeesion:AVCaptureSession?
    
    lazy var videoCaptureDevice:AVCaptureDevice? = {
       return AVCaptureDevice.default(for:AVMediaType.video)
    }()
    var vedioInput:AVCaptureDeviceInput?
    var vedioOutput:AVCaptureMovieFileOutput?
    var vedioConnection:AVCaptureConnection?
    
   lazy var audioCaptureDevice:AVCaptureDevice?  = {
        return AVCaptureDevice.default(for:AVMediaType.audio)
    }()
    var audioInput:AVCaptureDeviceInput?
    var audioOutput:AVCaptureAudioDataOutput?
    
    var recordTimer:Timer?
    lazy var vedioRecordUrl: URL = {
        var originPathUrl = URL.init(fileURLWithPath:NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!)
        originPathUrl.appendPathComponent("vedio.mp4")
        return originPathUrl
    }()
    
    var recordTime:Int = 0
    var isManulStopRecord = false
    
    //  MARK: - viewController lifeCycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCameraAuthorizeToCapture()
        
    }
    

    func getCameraAuthorizeToCapture() -> () {
  
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] (success) in
                if success {
                    DispatchQueue.main.async(execute: {
                        self.setCaptureConfigurationAndStartRunning()
                    })
                }
            }
        }else {
            setCaptureConfigurationAndStartRunning()
        }
    }
   
    func setCaptureConfigurationAndStartRunning() -> () {
        
        let trCaptureSeesion = AVCaptureSession.init()
        if trCaptureSeesion.canSetSessionPreset(AVCaptureSession.Preset.high) {
            trCaptureSeesion.sessionPreset = .high
        }else{
            trCaptureSeesion.sessionPreset = .medium
        }
        self.captureSeesion = trCaptureSeesion
        
        captureSeesion?.beginConfiguration()
        
        guard videoCaptureDevice != nil else {
            return
        }
        
        do {
             let trVedioInput = try AVCaptureDeviceInput.init(device: videoCaptureDevice!)
            if (captureSeesion?.canAddInput(trVedioInput))! {
                captureSeesion?.addInput(trVedioInput)
            }
            vedioInput = trVedioInput

        } catch {
            print("vedioInput init error\n")
        }
        
        let output = AVCaptureVideoDataOutput.init()
        let  trVedioOutput = AVCaptureMovieFileOutput.init()
        if (captureSeesion?.canAddOutput(trVedioOutput))! {
            captureSeesion?.addOutput(trVedioOutput)
        }
        vedioOutput = trVedioOutput
        
        let  trVedioConnection = vedioOutput?.connection(with: .video)
        trVedioConnection?.videoScaleAndCropFactor =  (trVedioConnection?.videoMaxScaleAndCropFactor)!
        if (trVedioConnection?.isVideoStabilizationSupported)! {
            trVedioConnection?.preferredVideoStabilizationMode = .auto
        }
        vedioConnection = trVedioConnection
        
        do {
            let trAudioInput = try AVCaptureDeviceInput.init(device: audioCaptureDevice!)
            if (captureSeesion?.canAddInput(trAudioInput))! {
                captureSeesion?.addInput(trAudioInput)
            }
            audioInput = trAudioInput
            
        } catch {
            print("audioInput init error\n")
        }
        
        let trPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSeesion!)
        trPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        trPreviewLayer.frame = view.frame
        view.layer.addSublayer(trPreviewLayer)
        bringControlViewsFront()
        
        captureSeesion?.commitConfiguration()
        captureSeesion?.startRunning()
    }
    
    func bringControlViewsFront() -> () {
        view.bringSubview(toFront: recordButton)
        view.bringSubview(toFront: recordTimeLabel)
        view.bringSubview(toFront: replayButton)
    }
    
    enum ButtonTitle:String {
        case startRecord
        case stopRecord
    }

    @IBAction func recordButtonTapped(_ sender: UIButton) {
        
        var isStartRecording = false
        
        switch sender.currentTitle {
        case ButtonTitle.startRecord.rawValue:
            sender.setTitle(ButtonTitle.stopRecord.rawValue, for: .normal)
            isStartRecording = true
        default:
            sender.setTitle(ButtonTitle.startRecord.rawValue, for: .normal)
        }
        
        if isStartRecording {
            
            replayButton.isEnabled = false
            
            if recordTimer == nil {
                recordTimer = Timer.init(timeInterval: 1.0, repeats: true, block: { [unowned self] (timer) in
                    self.updateTimeRecordLabel()
                })
            }
            RunLoop.main.add(recordTimer!, forMode: .commonModes)
            recordTimer?.fire()
            vedioOutput?.startRecording(to: vedioRecordUrl, recordingDelegate: self)
            
        } else {
            replayButton.isEnabled = true
            
            if recordTimer != nil {
                recordTimer?.invalidate()
                recordTimer = nil
            }
            vedioOutput?.stopRecording()
            isManulStopRecord = true
            restartTimeRecordLabel()
        }
        
    }
    
    @IBAction func replayButtonTapped(_ sender: Any) {
        
        
    }
    
    func restartTimeRecordLabel() -> () {
        recordTime = 0
        recordTimeLabel.text = "0:00:00"
    }
    
    func updateTimeRecordLabel() -> () {
        
        let hour = recordTime/3600
        let minute = (recordTime/60)%60
        let second = recordTime%60
        
        recordTimeLabel.text =  String.init(format: "%02d:%02d:%02d",hour,minute,second)
        recordTime += 1
        
    }
    
    func saveVedioToPhone() -> () {
        
        func writeVedioToPhotoLibrary(){
            PHPhotoLibrary.shared().performChanges({[unowned self] in
                
                PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: self.vedioRecordUrl)
                
            }) { [unowned self] (success, error) in
                defer {
                    do {
                        try FileManager.default.removeItem(at: self.vedioRecordUrl)
                    } catch let removeError {
                        print(removeError)
                    }
                }
                
                DispatchQueue.main.async {
                    guard success && error == nil else {
                        self.replayButton.isEnabled = false
                        return
                    }
                    
                    self.replayButton.isEnabled = true
                    self.replayButton.setTitleColor(UIColor.green, for: .normal)
                }
                
                print("performChanges creationRequestForAssetFromVideo  SUCCESS")
            }
        }
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { [unowned self] (status) in
                guard status == PHAuthorizationStatus.authorized else {
                    print("cannot proceed without permission")
                    return
                }
                writeVedioToPhotoLibrary()
            }
        }else{
            writeVedioToPhotoLibrary()
        }
    }
    
    
}


extension CameraCaptureViewController:AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("record end, outputFileURL = \(outputFileURL),\(String(describing: output.outputFileURL))")
        
        if outputFileURL.absoluteString.count == 0 {
            return
        }
        
        if isManulStopRecord {
            vedioRecordUrl = outputFileURL
            isManulStopRecord = false
            saveVedioToPhone()
        }else {
            do {
                try FileManager.default.removeItem(at: self.vedioRecordUrl)
            } catch let removeError {
                print(removeError)
            }
        }
        
    }
    
    
}
