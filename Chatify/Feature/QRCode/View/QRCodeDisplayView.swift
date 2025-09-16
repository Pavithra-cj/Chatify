//
//  QRCodeDisplayView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct QRCodeDisplayView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView{
            VStack {
                if let userId = Auth.auth().currentUser?.uid,
                   let qrImage = QRCodeGenerator.generateQRCode(from: "\(userId)_\(UUID().uuidString)") {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    Text("Scan this code to add me as a friend")
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("My QR Code")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    QRCodeDisplayView()
}
