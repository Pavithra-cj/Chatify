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
                return "None"
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
    
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                DispatchQueue.main.async {
                    self.biometricError = error
                }
            }
            return .none
        }
        
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            @unknown default:
                return .none
            }
        }
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
    }
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        // Check if authentication is still valid
        if isAuthenticated {
            if let lastAuth = UserDefaults.standard.object(forKey: "lastAuthenticationDate") as? Date {
                let elapsed = Date().timeIntervalSince(lastAuth)
                if elapsed < authenticationValidityDuration {
                    completion(true)
                    return
                }
            }
        }
        
        guard biometricType != .none else {
            DispatchQueue.main.async {
                self.biometricError = NSError(domain: "com.chatify", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is not available"])
                self.isAuthenticated = false
                completion(false)
            }
            return
        }
        
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                             localizedReason: "Authenticate to access Chatify") { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success {
                    self.biometricError = nil
                    self.isAuthenticated = true
                    UserDefaults.standard.set(Date(), forKey: "lastAuthenticationDate")
                    completion(true)
                } else {
                    self.biometricError = error
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
