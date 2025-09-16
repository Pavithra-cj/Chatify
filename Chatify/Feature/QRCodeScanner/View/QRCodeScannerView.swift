//
//  QRCodeScannerView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import SwiftUI

struct QRCodeScannerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: QRCodeScannerViewModel
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, QRScannerCoordinatorDelegate {
        private let viewModel: QRCodeScannerViewModel
        init(viewModel: QRCodeScannerViewModel) { self.viewModel = viewModel }
        
        func qrScanner(didFind code: String) {
            Task { @MainActor in
                viewModel.onCodeScanned(code)
            }
        }
    }
}
