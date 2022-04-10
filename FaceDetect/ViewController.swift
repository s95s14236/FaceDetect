//
//  ViewController.swift
//  FaceDetect
//
//  Created by Steven Wang on 2022/4/8.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var previewView: UIView?
    
    // AVCapture variables to hold camera content
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var captureDevice: AVCaptureDevice?
    
    // Layer UI for drawing Vision results
    var rootLayer: CALayer?
    private var faceLayers: [CAShapeLayer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.session = self.setupAVCaptureSession()
                
        self.session?.startRunning()
    }

    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        // 創建捕獲會話
        let captureSession = AVCaptureSession()
        
        do {
            let captureDevice = try self.configureFrontCamera(for: captureSession)
            self.configureVideoDataOutput(for: captureDevice, captureSession: captureSession)
            self.designatePreviewLayer(for: captureSession)
            return captureSession
        } catch let excutionError as NSError {
            print("excutionError: ", excutionError.localizedDescription)
        } catch {
            print("An unexpected failure has occured")
        }
        
        self.teardownAVCapture()

        return nil
    }
    

    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> AVCaptureDevice {
        
        // 創建捕獲設備
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("No front video camera available")
        }
        
        // 創建捕獲輸入
        if let deviceInput = try? AVCaptureDeviceInput(device: camera) {
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
            
            return camera
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /**
     設定video 輸出樣本
     */
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, captureSession: AVCaptureSession) {
        // 捕獲輸出
        let videoDataOutput = AVCaptureVideoDataOutput()
        // 後面的video frames會被丟棄，不會排隊等待處理
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "camera.queue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        // 在input與output中建立連接
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: .video) {
            // 是否配置比或管道來傳遞相機info
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
            captureConnection.videoOrientation = .portrait
        }
        
        self.captureDevice = inputDevice
    }
    
    /**
     捕獲video info 進行即時預覽
     */
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer

        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        // 保持video寬高比, 填滿範圍, video會被裁剪
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        if let previewRootLayer = self.previewView?.layer {
            self.rootLayer = previewRootLayer
            previewRootLayer.masksToBounds = true
            videoPreviewLayer.frame = previewRootLayer.bounds
            previewRootLayer.addSublayer(videoPreviewLayer)
        }
        
    }
    
    /**
     destroy AVCapture
     */
    fileprivate func teardownAVCapture() {
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // new 臉部辨識request
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                self.faceLayers.forEach { drawing in
                    drawing.removeFromSuperlayer()
                }
                if let observations = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionObservations(observations: observations)
                }
            }
        })
        
        // new image handler處理camera 擷取的每個image buffer
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])
        
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print("perform fail, error: ", error.localizedDescription)
        }
    }
    
    /**
     draw the rectangle on face
     */
    fileprivate func handleFaceDetectionObservations(observations: [VNFaceObservation]) {
        for observation in observations {
            if let previewLayer = self.previewLayer {
                let faceRectConverted = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
                let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
                
                let faceLayer = CAShapeLayer()
                faceLayer.path = faceRectanglePath
                faceLayer.fillColor = UIColor.clear.cgColor
                faceLayer.strokeColor = UIColor.yellow.cgColor
                
                self.faceLayers.append(faceLayer)
                self.view.layer.addSublayer(faceLayer)
            }
        }
    }
}
