//
//  EditProfileView.swift
//  Agrisense
//
//  Created by GitHub Copilot on 25/10/25.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var location: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Image
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.green, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            if let user = userManager.currentUser {
                                Text(user.name.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // Camera icon overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.green)
                                            .clipShape(Circle())
                                    }
                                    .disabled(isUploading)
                                }
                            }
                            .frame(width: 100, height: 100)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section(header: Text(localizationManager.localizedString(for: "full_name"))) {
                    TextField(localizationManager.localizedString(for: "enter_full_name_placeholder"), text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
                
                Section(header: Text(localizationManager.localizedString(for: "phone_number_label"))) {
                    TextField(localizationManager.localizedString(for: "enter_phone_placeholder"), text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Location")) {
                    TextField("Enter your location", text: $location)
                        .textContentType(.addressCity)
                        .autocapitalization(.words)
                }
                
                Section {
                    HStack {
                        Text(localizationManager.localizedString(for: "email_address_label"))
                        Spacer()
                        Text(userManager.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "edit_profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: "done")) {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || isUploading)
                }
            }
            .onAppear {
                if let user = userManager.currentUser {
                    name = user.name
                    phoneNumber = user.phoneNumber ?? ""
                    location = user.location ?? ""
                }
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(localizationManager.localizedString(for: "uploading"))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .alert(localizationManager.localizedString(for: "error_occurred"), isPresented: $showError) {
                Button(localizationManager.localizedString(for: "dismiss"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveProfile() {
        Task {
            do {
                // Update user profile
                try await userManager.updateUserProfile(name: name, phoneNumber: phoneNumber, location: location)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(UserManager())
            .environmentObject(LocalizationManager.shared)
    }
}
