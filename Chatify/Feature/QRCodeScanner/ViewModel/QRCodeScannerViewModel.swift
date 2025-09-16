//
//  QRCodeScannerViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
class QRCodeScannerViewModel: ObservableObject {
    @Published var scannedCode: String? = nil
    @Published var isScanning: Bool = false
    
    func onCodeScanned(_ code: String) {
        scannedCode = code
        isScanning = false
    }
    
    func reset() {
        scannedCode = nil
        isScanning = true
    }
}
