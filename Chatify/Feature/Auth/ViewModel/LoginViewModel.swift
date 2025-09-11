//
//  LoginViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-11.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""
    @Published var showErrorAlert: Bool = false
    @Published var showPassword: Bool = false
    @Published var showForgotPassword: Bool = false
    @Published var showSignUp: Bool = false
    @Published var logoAppeared: Bool = false
    
    let alreadyLoggedIn: () -> ()
    
    init(alreadyLoggedIn: @escaping () -> ()) {
        self.alreadyLoggedIn = alreadyLoggedIn
    }
    
    func handleLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showErrorAlert = true
                } else {
                    self.alreadyLoggedIn()
                }
            }
        }
    }
}
