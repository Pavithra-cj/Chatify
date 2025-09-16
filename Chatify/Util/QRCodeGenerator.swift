//
//  QRCodeGenerator.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import Foundation
import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeGenerator {
    static func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"
        
        guard let qrCodeImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQRCode = qrCodeImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledQRCode, from: scaledQRCode.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
