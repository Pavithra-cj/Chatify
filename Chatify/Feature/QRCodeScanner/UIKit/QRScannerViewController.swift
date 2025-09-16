//
//  QRScannerViewController.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import Foundation
import UIKit
import AVFoundation

final class QRScannerViewController: UIViewController {
    private var coordinator: QRScannerCoordinator!
    weak var delegate: QRScannerCoordinatorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coordinator?.stop()
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    private func setupCamera() {
        coordinator = QRScannerCoordinator(delegate: delegate!)
        let previewLayer = coordinator.makePreviewLayer(for: view)
        view.layer.addSublayer(previewLayer)
        coordinator.start()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = view.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = view.layer.bounds
        }
    }
}
