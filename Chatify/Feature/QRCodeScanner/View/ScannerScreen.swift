//
//  ScannerScreen.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import SwiftUI
import AVFoundation

struct ScannerScreen: View {
    @StateObject private var viewModel = QRCodeScannerViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var isCheckingPermission = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isCheckingPermission {
                    ProgressView("Checking camera permission...")
                } else if let code = viewModel.scannedCode {
                    VStack(spacing: 20) {
                        Text("QR Code Scanned!")
                            .font(.title2)
                            .padding()
                        
                        Button("Scan Again") {
                            viewModel.reset()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    QRCodeScannerView(viewModel: viewModel)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert("Camera Permission", isPresented: $showingPermissionAlert) {
                Button("Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(permissionAlertMessage)
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                Button("OK") {
                    // Success
                    if viewModel.alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkCameraPermission()
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCheckingPermission = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isCheckingPermission = false
                    if !granted {
                        showPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            isCheckingPermission = false
            showPermissionAlert()
        @unknown default:
            isCheckingPermission = false
        }
    }
    
    private func showPermissionAlert() {
        permissionAlertMessage = "Camera access is required to scan QR codes. Please enable it in Settings."
        showingPermissionAlert = true
    }
}
