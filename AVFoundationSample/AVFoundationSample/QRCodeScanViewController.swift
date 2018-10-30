//
//  QRCodeScanViewController.swift
//  AVFoundationSample
//
//  Created by 朱慧林 on 2018/10/17.
//  Copyright © 2018年 朱慧林. All rights reserved.
//

import UIKit
import AVFoundation
import MBProgressHUD

class QRCodeScanViewController: UIViewController {
    
    var captureSession:AVCaptureSession?

   @objc lazy var device:AVCaptureDevice? = {
        
        let device = AVCaptureDevice.default(for:AVMediaType.video)
        do {
            try device?.lockForConfiguration()
            if device!.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus) {
                device?.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
            }
            
            if device!.isAutoFocusRangeRestrictionSupported {
                device?.autoFocusRangeRestriction = AVCaptureDevice.AutoFocusRangeRestriction.near
            }
            
            if device!.isExposurePointOfInterestSupported {
                device?.exposurePointOfInterest = (device?.focusPointOfInterest)!
            }
            
            if device!.isExposureModeSupported(AVCaptureDevice.ExposureMode.autoExpose) {
                device?.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
            }
            device?.isSubjectAreaChangeMonitoringEnabled = true
        }catch {
            print("device?.lockForConfiguration throws error=\(error)")
        }
        device?.unlockForConfiguration()
        return device
    }()
    var vedioInput:AVCaptureDeviceInput?
//    var vedioOutput:AVCapturePhotoOutput?
    var vedioOutput:AVCaptureMetadataOutput?
    var vedioConnection:AVCaptureConnection?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    
    var isHadScaled:Bool = false
    
    lazy var zoomFactor:CGFloat = {
        var zoomFactor:CGFloat = 4.0
    
        return zoomFactor
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let gestureRec = UITapGestureRecognizer.init(target: self, action: #selector(self.scanViewIsTapped(_:)))
        gestureRec.numberOfTapsRequired = 2
        view.addGestureRecognizer(gestureRec)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: #keyPath(QRCodeScanViewController.device.isAdjustingFocus))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCameraAuthorizeToCapture()
        
        NotificationCenter.default.addObserver(self, selector: #selector(captureDeviceSubjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: device)
        addObserver(self, forKeyPath: #keyPath(QRCodeScanViewController.device.isAdjustingFocus), options: [NSKeyValueObservingOptions.initial,NSKeyValueObservingOptions.new], context: nil)

    }

    //    MARK:- target -
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(device.isAdjustingFocus) {
            print("device.isAdjustingFocus changed or initialed ,change=\(change)")
        }
    }
    
    @objc func scanViewIsTapped(_ guesture:UITapGestureRecognizer){
        
        do {
            try device?.lockForConfiguration()
            
            if device!.isFocusPointOfInterestSupported {
                device?.focusPointOfInterest = (videoPreviewLayer?.captureDevicePointConverted(fromLayerPoint: guesture.location(in: guesture.view)))!
            }
            
                if isHadScaled  {
                    isHadScaled = false
                    device?.ramp(toVideoZoomFactor:1, withRate: 3.0)

                } else {
                    isHadScaled = true
                    device?.ramp(toVideoZoomFactor: zoomFactor, withRate: 3.0)
                                    }
            
        } catch {
            print("[QRcodeScanner] device lockForConfiguration throws error=\(error)")
        }
        device?.unlockForConfiguration()
     
    }
    
//    证明不需要，这个功能
//    func manualSetLayerZoom() -> () {
//        let transform = videoPreviewLayer!.transform
//        CATransaction.begin()
//        CATransaction.setCompletionBlock {
//        }
//        CATransaction.setAnimationDuration(1.0)
//        videoPreviewLayer!.transform = CATransform3DScale(transform, zoomFactor, zoomFactor, 1.0)
//        CATransaction.commit()
//    }

//    // *不能使用者方法，因为这个outPut情况下的最大scaleAndCropFactor是1，所以不能够放大*
//    func setVideoScaleAndCropFactor() -> () {
//        vedioConnection?.videoScaleAndCropFactor =  vedioConnection!.videoScaleAndCropFactor/self.scaleAndCropFactor
//    }

    
    @objc func captureDeviceSubjectAreaDidChange(_ noti:NSNotification){
        print("captureDeviceSubjectAreaDidChange")
    }
    
}

extension QRCodeScanViewController:AVCapturePhotoCaptureDelegate {
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("AVCapturePhotoCaptureDelegate  didFinishProcessingPhoto AVCapturePhoto=\(photo)")
        if error == nil {
            if let cgimage = photo.cgImageRepresentation() {
                let ciImage = CIImage.init(cgImage: cgimage.takeUnretainedValue())
                
                let QRMessage = messageFromQRCodeImage(ciImage)
                print("QRmessage=\(String(describing: QRMessage))")
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?){
        print("AVCapturePhotoCaptureDelegate  didFinishProcessingPhoto photoSampleBuffer=\(String(describing: photoSampleBuffer))")

    }
    
    func messageFromQRCodeImage(_ image:CIImage) -> String? {
        let context = CIContext.init(options: nil)
        let detector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
        let features = detector?.features(in: image)
        
        if features?.count == 0 {
            return nil
        }
        
        let QRFeature = features?.first as! CIQRCodeFeature
        return QRFeature.messageString
    }
    
    
}


extension QRCodeScanViewController:AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        MBProgressHUD.showAdded(to: UIApplication.shared.delegate!.window!!, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
            MBProgressHUD.hide(for: UIApplication.shared.delegate!.window!!, animated: true)
        }
        print("AVCaptureMetadataOutputObjectsDelegate metadataOutput  didOutput metadataObjects =\(metadataObjects)")
        if metadataObjects.count == 0 {
            return
        }
        
        guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {
            return
        }
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            _ = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            
        if metadataObj.stringValue != nil {
                    print("AVCaptureMetadataOutputObjectsDelegate metadataObj.stringValue=\(String(describing: metadataObj.stringValue))")
                }
            }
        }
    
}


extension QRCodeScanViewController {
    
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
        self.captureSession = trCaptureSeesion
        
        captureSession?.beginConfiguration()
        
        guard device != nil else {
            return
        }
        
        do {
            let trVedioInput = try AVCaptureDeviceInput.init(device: device!)
            if (captureSession?.canAddInput(trVedioInput))! {
                captureSession?.addInput(trVedioInput)
            }
            vedioInput = trVedioInput
            
        } catch {
            print("vedioInput init error\n")
        }
        
        //        let  trVedioOutput = AVCapturePhotoOutput.init()
        let  trVedioOutput = AVCaptureMetadataOutput.init()
        if (captureSession?.canAddOutput(trVedioOutput))! {
            captureSession?.addOutput(trVedioOutput)
            trVedioOutput.metadataObjectTypes  = trVedioOutput.availableMetadataObjectTypes
            trVedioOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        }
        vedioOutput = trVedioOutput
        
        
        if let trVedioConnection = vedioOutput?.connection(with: .video), trVedioConnection.isVideoStabilizationSupported {
            trVedioConnection.preferredVideoStabilizationMode = .auto
            vedioConnection = trVedioConnection
        }else {
            vedioConnection = vedioOutput?.connections[0]
        }
        
        
        let trPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession!)
        trPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        trPreviewLayer.frame = view.frame
        view.layer.addSublayer(trPreviewLayer)
        videoPreviewLayer = trPreviewLayer
        
        captureSession?.commitConfiguration()
        captureSession?.startRunning()
    }
    
    
}
