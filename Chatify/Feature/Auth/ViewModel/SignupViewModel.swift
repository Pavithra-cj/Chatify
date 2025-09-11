//
//  SignupViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-11.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import FirebaseCore

@MainActor
class SignupViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""
    @Published var showErrorAlert: Bool = false
    @Published var showSuccessAlert: Bool = false
    
    @Published var shouldShowImagePicker: Bool = false
    @Published var image: UIImage?
    
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    @Published var logoAppeared: Bool = false
    
    let alreadyLoggedIn: () -> ()
    
    init(alreadyLoggedIn: @escaping () -> ()) {
        self.alreadyLoggedIn = alreadyLoggedIn
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func handleSignUp() {
        guard !email.isEmpty, !password.isEmpty,
              !confirmPassword.isEmpty, !name.isEmpty,
              !username.isEmpty else {
            alertMessage = "Please fill in all fields"
            showErrorAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showErrorAlert = true
            return
        }
        
        guard let originalImage = image else {
            alertMessage = "Please select a profile image!"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        // Resize + convert image
        let resizedImage = resizeImage(originalImage, targetSize: CGSize(width: 150, height: 150))
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.2) else {
            alertMessage = "Failed to process image"
            showErrorAlert = true
            isLoading = false
            return
        }
        let base64Image = imageData.base64EncodedString()
        
        // Firebase create user
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Failed to create user: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    return
                }
                
                guard let uid = result?.user.uid else { return }
                
                let userData: [String: Any] = [
                    "uid": uid,
                    "name": self.name,
                    "username": self.username,
                    "email": self.email,
                    "profileImage": base64Image
                ]
                
                Firestore.firestore().collection("user").document(uid).setData(userData) { err in
                    if let err = err {
                        self.alertMessage = "Failed to save user data: \(err.localizedDescription)"
                        self.showErrorAlert = true
                        return
                    }
                }
                
                self.alertMessage = "Account created successfully!"
                self.showSuccessAlert = true
            }
        }
    }
}
