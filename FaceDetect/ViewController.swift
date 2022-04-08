//
//  ViewController.swift
//  FaceDetect
//
//  Created by Steven Wang on 2022/4/8.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var previewView: UIView!
    
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var captureDevice: AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.session = self.setupAVCaptureSession()
    }

    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        // 創建捕獲會話
        let captureSession = AVCaptureSession()
        
        do {
            self.captureDevice = try self.configureFrontCamera(for: captureSession)
            self.configureVideoDataOutput(for: self.captureDevice, captureSession: captureSession)
//            self.designatePreviewLayer()
        } catch {
            
        }
        
        
        return captureSession
    }
    

    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> AVCaptureDevice {
        
        // 創建捕獲設備
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("No front video camera available")
        }
        
        // 創建捕獲輸入
        if let deviceInput = try? AVCaptureDeviceInput(device: captureDevice!) {
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
            
            return camera
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, captureSession: AVCaptureSession) {
        // 捕獲輸出
        let videoDataOutput = AVCaptureVideoDataOutput()
        // 後面的video frames會被丟棄，不會排隊等待處理
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
//        let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")
//        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: .video) {
            // 是否配置比或管道來傳遞相機info
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
    }
    
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer

        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        
        
    }
    
    
    
}

