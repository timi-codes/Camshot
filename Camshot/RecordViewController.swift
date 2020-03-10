//
//  CameraViewController.swift
//  Camshot
//
//  Created by Timi Tejumola on 06/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import UIKit
import SwiftUI
import AVFoundation


class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var switchCam: UIButton!
    
    var captureSession = AVCaptureSession()
    
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    
    var videoFileOutput:AVCaptureMovieFileOutput?

    
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    var isRecording = false
    var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomInGestureRecognizer = UISwipeGestureRecognizer()
    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nav = self.navigationController?.navigationBar
        nav?.isHidden = true
        
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
        
//        toggleCameraGestureRecognizer.direction = .up
//        toggleCameraGestureRecognizer.addTarget(self, action: #selector(self.switchCamera))
//        view.addGestureRecognizer(toggleCameraGestureRecognizer)
//
        // Zoom In recognizer
        zoomInGestureRecognizer.direction = .right
        zoomInGestureRecognizer.addTarget(self, action: #selector(zoomIn))
        view.addGestureRecognizer(zoomInGestureRecognizer)
        
        // Zoom Out recognizer
        zoomOutGestureRecognizer.direction = .left
        zoomOutGestureRecognizer.addTarget(self, action: #selector(zoomOut))
        view.addGestureRecognizer(zoomOutGestureRecognizer)
    }
    
    func setupCaptureSession(){
        captureSession.sessionPreset = AVCaptureSession.Preset.high
    }
    
    func setupDevice(){
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentDevice = backCamera
    }
    
    func setupInputOutput(){
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            videoFileOutput = AVCaptureMovieFileOutput()
            captureSession.addOutput(videoFileOutput!)
        }catch(let error){
            print(error.localizedDescription)
        }
    }
    
    func setupPreviewLayer(){
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    func startRunningCaptureSession(){
        captureSession.startRunning()
    }
    
    @IBAction func startRecordingButton(_ sender: UIButton) {
        
        if !isRecording {
           isRecording = true
            
           UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: { () -> Void in
                 self.recordButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
             }, completion: nil)
             
           let outputPath = NSTemporaryDirectory() + "output.mov"
           let outputFileURL = URL(fileURLWithPath: outputPath)
           videoFileOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
            
        }else {
            
            isRecording = false
             UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: { () -> Void in
                 self.recordButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
             }, completion: nil)
             
             recordButton.layer.removeAllAnimations()
             videoFileOutput?.stopRecording()
        }
    }
    
    
    @IBAction func switchCamera(_ sender: UIButton) {
        captureSession.beginConfiguration()
        
        // Change the device based on the current camera
        let newDevice = (currentDevice?.position == AVCaptureDevice.Position.back) ? frontCamera : backCamera
        
        // Remove all inputs from the session
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        // Change to the new input
        let cameraInput:AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    @objc func zoomIn() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor < 5.0 {
                let newZoomFactor = min(zoomFactor + 1.0, 5.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    @objc func zoomOut() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor > 1.0 {
                let newZoomFactor = max(zoomFactor - 1.0, 1.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate methods
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        
        performSegue(withIdentifier: "previewVideo", sender: outputFileURL)
        self.captureSession.stopRunning()

    }
    
    // MARK: - PREPARE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "previewVideo" {
            let previewViewController = segue.destination as! PreviewViewController
            previewViewController.videoUrl = (sender as! URL)
        }
    }
}
