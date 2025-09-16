//
//  QRScannerCoordinator.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import Foundation
import UIKit
import AVFoundation

protocol QRScannerCoordinatorDelegate: AnyObject {
    func qrScanner(didFind code: String)
}

class QRScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private let captureSession = AVCaptureSession()
    private weak var delegate: QRScannerCoordinatorDelegate?
    
    init(delegate: QRScannerCoordinatorDelegate) {
        self.delegate = delegate
        super.init()
        setUp()
    }
    
    private func setUp() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
            return
        }
    }
    
    func makePreviewLayer(for view: UIView) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    func start() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        stop()
        delegate?.qrScanner(didFind: stringValue)
    }
}
