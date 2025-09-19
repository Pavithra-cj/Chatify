import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class SettingsViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var profileImage: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    init() {
        fetchUserData()
    }
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        Firestore.firestore().collection("user").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let data = snapshot?.data() else { return }
            self.userName = data["username"] as? String ?? ""
            self.userEmail = data["email"] as? String ?? ""
            self.profileImage = data["profileImage"] as? String
        }
    }
    
    func updateUserProfile(newUsername: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        Firestore.firestore().collection("user").document(uid).updateData([
            "username": newUsername
        ]) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            self.userName = newUsername
            completion(true)
        }
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(false)
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        isLoading = true
        
        Firestore.firestore().collection("user").document(uid).updateData([
            "profileImage": base64String
        ]) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            self.profileImage = base64String
            completion(true)
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Bool, String) -> Void) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            completion(false, "User not found")
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                completion(true, "Password updated successfully")
            }
        }
    }
}
