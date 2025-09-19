import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditingProfile = false
    @State private var newUsername = ""
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: UIImage?
    
    var body: some View {
        Form {
            Section(header: Text("Profile Picture")) {
                HStack {
                    Spacer()
                    if let base64String = viewModel.profileImage,
                       let imageData = Data(base64Encoded: base64String),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 100)
                    }
                    Spacer()
                }
                .onTapGesture {
                    showingImagePicker = true
                }
                
                if !isEditingProfile {
                    Text("Tap image to change profile picture")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            Section(header: Text("User Information")) {
                if isEditingProfile {
                    TextField("Username", text: $newUsername)
                        .autocapitalization(.none)
                        .textContentType(.username)
                } else {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(viewModel.userName)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Text("Email")
                    Spacer()
                    Text(viewModel.userEmail)
                        .foregroundColor(.gray)
                }
                .opacity(0.8)
                
                if !isEditingProfile {
                    Text("Email cannot be changed")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            Section {
                if isEditingProfile {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Cancel") {
                        isEditingProfile = false
                        newUsername = viewModel.userName
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Edit Profile") {
                        isEditingProfile = true
                        newUsername = viewModel.userName
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, image in
            if let image = image {
                viewModel.uploadProfileImage(image) { success in
                    if success {
                        alertMessage = "Profile picture updated successfully"
                    } else {
                        alertMessage = viewModel.errorMessage
                    }
                    showingAlert = true
                }
            }
        }
        .alert("Profile Update", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
    
    private func saveChanges() {
        guard !newUsername.isEmpty else {
            alertMessage = "Username cannot be empty"
            showingAlert = true
            return
        }
        
        viewModel.updateUserProfile(newUsername: newUsername) { success in
            if success {
                alertMessage = "Profile updated successfully"
                isEditingProfile = false
            } else {
                alertMessage = viewModel.errorMessage
            }
            showingAlert = true
        }
    }
}
