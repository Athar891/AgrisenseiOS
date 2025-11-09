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
    @State private var profileImage: UIImage?
    @State private var imageForCropping: UIImage?
    @State private var showImageCropper = false
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
                            
                            // Display profile image if available
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let user = userManager.currentUser, let imageURL = user.profileImage, !imageURL.isEmpty {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    case .failure(let error):
                                        VStack {
                                            Text(user.name.prefix(1).uppercased())
                                                .font(.system(size: 40, weight: .bold))
                                                .foregroundColor(.white)
                                            #if DEBUG
                                            Text("Load failed")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                            #endif
                                        }
                                    case .empty:
                                        VStack {
                                            Text(user.name.prefix(1).uppercased())
                                                .font(.system(size: 40, weight: .bold))
                                                .foregroundColor(.white)
                                            ProgressView()
                                                .tint(.white)
                                                .scaleEffect(0.7)
                                        }
                                    @unknown default:
                                        Text(user.name.prefix(1).uppercased())
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            } else if let user = userManager.currentUser {
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
                
                Section(header: Text(localizationManager.localizedString(for: "email_address_label"))) {
                    Text(userManager.currentUser?.email ?? "")
                        .foregroundColor(.secondary)
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
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    if let newValue = newValue {
                        await loadImageForCropping(from: newValue)
                    }
                }
            }
            .sheet(isPresented: $showImageCropper) {
                if let image = imageForCropping {
                    ImageCropperView(image: image) { croppedImage in
                        Task {
                            await uploadCroppedImage(croppedImage)
                        }
                    }
                    .environmentObject(localizationManager)
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
    
    private func loadImageForCropping(from item: PhotosPickerItem) async {
        do {
            // Load the image data from PhotosPickerItem
            guard let data = try await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    errorMessage = "Failed to load selected image"
                    showError = true
                }
                return
            }
            
            #if DEBUG
            print("✅ Image data loaded successfully, size: \(data.count) bytes")
            // Check file signature
            let bytes = [UInt8](data.prefix(12))
            print("📋 File signature: \(bytes.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " "))")
            #endif
            
            // Create UIImage from data
            guard let uiImage = UIImage(data: data) else {
                await MainActor.run {
                    errorMessage = "Failed to process selected image. Please try a different image."
                    showError = true
                }
                return
            }
            
            #if DEBUG
            print("✅ UIImage created successfully, size: \(uiImage.size)")
            #endif
            
            // Show cropper
            await MainActor.run {
                imageForCropping = uiImage
                showImageCropper = true
            }
            
        } catch {
            #if DEBUG
            print("❌ Error loading image: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
            }
            #endif
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func uploadCroppedImage(_ croppedImage: UIImage) async {
        await MainActor.run {
            isUploading = true
        }
        
        do {
            // Update local preview
            await MainActor.run {
                profileImage = croppedImage
            }
            
            // Upload to Cloudinary
            let imageUrl = try await userManager.uploadProfileImage(croppedImage)
            
            #if DEBUG
            print("✅ Image uploaded successfully to: \(imageUrl)")
            print("✅ Current user profile image: \(userManager.currentUser?.profileImage ?? "nil")")
            #endif
            
            await MainActor.run {
                isUploading = false
            }
        } catch {
            #if DEBUG
            print("❌ Error uploading image: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
            }
            #endif
            await MainActor.run {
                profileImage = nil
                errorMessage = error.localizedDescription
                showError = true
                isUploading = false
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
