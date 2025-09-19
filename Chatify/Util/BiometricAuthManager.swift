//
//  BiometricAuthManager.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-18.
//

import LocalAuthentication
import SwiftUI

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false {
        didSet {
            if isAuthenticated {
                UserDefaults.standard.set(Date(), forKey: "lastAuthenticationDate")
            }
        }
    }
    @Published var biometricError: Error?
    @Published var biometricType: BiometricType = .none
    
    private let authenticationValidityDuration: TimeInterval = 300
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        
        var title: String {
            switch self {
            case .none:
                return "Passcode"
            case .touchID:
                return "Touch ID"
            case .faceID:
                return "Face ID"
            }
        }
    }
    
    init() {
        biometricType = getBiometricType()
        checkPreviousAuthentication()
    }
    
    private func checkPreviousAuthentication() {
        if let lastAuth = UserDefaults.standard.object(forKey: "lastAuthenticationDate") as? Date {
            let elapsed = Date().timeIntervalSince(lastAuth)
            if elapsed < authenticationValidityDuration {
                isAuthenticated = true
                return
            }
        }
        isAuthenticated = false
    }
    
    func refreshBiometricType() { biometricType = getBiometricType() }
    
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .none: return .none
            case .touchID: return .touchID
            case .faceID: return .faceID
            @unknown default: return .none
            }
        }
        return .touchID
    }
    
    func authenticate(force: Bool = false, completion: @escaping (Bool) -> Void) {
        // Respect cached auth unless force is specified.
        if !force, isAuthenticated, let lastAuth = UserDefaults.standard.object(forKey: "lastAuthenticationDate") as? Date {
            let elapsed = Date().timeIntervalSince(lastAuth)
            if elapsed < authenticationValidityDuration {
                completion(true)
                return
            }
        }
        
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?
        
        let chosenPolicy: LAPolicy
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            chosenPolicy = .deviceOwnerAuthenticationWithBiometrics
        } else {
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                chosenPolicy = .deviceOwnerAuthentication
            } else {
                DispatchQueue.main.async {
                    self.biometricError = error
                    self.isAuthenticated = false
                    completion(false)
                }
                return
            }
        }
        
        context.evaluatePolicy(chosenPolicy, localizedReason: "Authenticate to access Chatify") { [weak self] success, evalError in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.biometricError = nil
                    self.isAuthenticated = true
                    UserDefaults.standard.set(Date(), forKey: "lastAuthenticationDate")
                    completion(true)
                } else {
                    if let laError = evalError as? LAError, laError.code == .biometryLockout, chosenPolicy == .deviceOwnerAuthenticationWithBiometrics {
                        self.forcePasscodeFallback(completion: completion)
                        return
                    }
                    self.biometricError = evalError
                    self.isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "lastAuthenticationDate")
                    completion(false)
                }
            }
        }
    }
    
    private func forcePasscodeFallback(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            self.biometricError = error
            self.isAuthenticated = false
            completion(false)
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate with Passcode") { [weak self] success, evalError in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.biometricError = nil
                    self.isAuthenticated = true
                    UserDefaults.standard.set(Date(), forKey: "lastAuthenticationDate")
                    completion(true)
                } else {
                    self.biometricError = evalError
                    self.isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "lastAuthenticationDate")
                    completion(false)
                }
            }
        }
    }
    
    func reset() {
        isAuthenticated = false
        biometricError = nil
        UserDefaults.standard.removeObject(forKey: "lastAuthenticationDate")
    }
}
