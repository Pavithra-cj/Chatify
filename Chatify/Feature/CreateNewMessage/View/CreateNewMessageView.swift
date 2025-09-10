//
//  CreateNewMessageView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import SwiftUI

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView{
            ScrollView{
                ForEach(vm.users) { user in
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack (spacing: 16) {
                            if let base64String = user.profileImage,
                               let imageData = Data(base64Encoded: base64String),
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipped()
                                    .cornerRadius(50)
                                    .overlay(
                                        RoundedRectangle(
                                            cornerRadius: 44
                                        )
                                        .stroke(Color.black, lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                            }
                            VStack{
                                Text(user.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(.label))
                                
                                Text(user.email)
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(Color(.label))
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    Divider()
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle(Text("New Message"))
            .toolbar{
                ToolbarItemGroup(placement:
                        .navigationBarLeading){
                            Button{
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Text("Cancel")
                            }
                        }
            }
        }
    }
}

#Preview {
    CreateNewMessageView{ user in
        print("Selected user: \(user)")
    }
}
