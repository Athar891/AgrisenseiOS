import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false
    @State private var showingSettings = false
    
    // Use PhotosPickerItem for modern photo picking
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUpdatingProfile = false
    
    // Local state for text fields to enable editing
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var location: String = ""  // Changed from address to location to match User model
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeader(
                        user: $userManager.currentUser,
                        isEditing: $isEditing,
                        name: $name,
                        phoneNumber: $phoneNumber,
                        location: $location,
                        selectedPhotoItem: $selectedPhotoItem,
                        isUpdatingProfile: $isUpdatingProfile
                    )
                    
                    // Dark Mode Toggle
                    HStack {
                        Image(systemName: appState.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(appState.isDarkMode ? .purple : .orange)
                        
                        Text("Dark Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Toggle("", isOn: $appState.isDarkMode)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Sign Out Button
                    Button(action: {
                        userManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                Text("Settings View") // Placeholder
            }
            .onAppear(perform: loadInitialUserData)
            .onChange(of: selectedPhotoItem, handlePhotoSelection)
            .onChange(of: isEditing) { oldValue, newValue in
                handleEditModeChange(from: oldValue, to: newValue)
            }
        }
    }
    
    private func loadInitialUserData() {
        if let user = userManager.currentUser {
            name = user.name
            phoneNumber = user.phoneNumber ?? ""
            location = user.location ?? ""
        }
    }
    
    private func handleEditModeChange(from wasEditing: Bool, to isNowEditing: Bool) {
        if wasEditing && !isNowEditing {
            Task {
                await saveProfileChanges()
            }
        } else if !wasEditing && isNowEditing {
            loadInitialUserData()
        }
    }
    
    private func saveProfileChanges() async {
        isUpdatingProfile = true
        defer { isUpdatingProfile = false }
        
        do {
            try await userManager.updateUserProfile(
                name: name,
                phoneNumber: phoneNumber,
                location: location
            )
        } catch {
            print("Error saving profile details: \(error.localizedDescription)")
        }
    }
    
    private func handlePhotoSelection(from oldItem: PhotosPickerItem?, to newItem: PhotosPickerItem?) {
        guard let item = newItem else { return }
        
        Task {
            isUpdatingProfile = true
            defer { isUpdatingProfile = false }
            
            do {
                guard let data = try await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) else {
                    print("Failed to load image data.")
                    return
                }
                
                // Upload the profile image - UserManager will update the current user
                _ = try await userManager.uploadProfileImage(uiImage)
                
            } catch {
                print("Error processing new profile image: \(error.localizedDescription)")
            }
        }
    }
}

struct ProfileHeader: View {
    @Binding var user: User?
    @Binding var isEditing: Bool
    @Binding var name: String
    @Binding var phoneNumber: String
    @Binding var location: String
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var isUpdatingProfile: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Group {
                        if let profileImage = user?.profileImage, let url = URL(string: profileImage) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .overlay(isUpdatingProfile ? ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.2)).clipShape(Circle()) : nil)
                }
                .disabled(!isEditing && !isUpdatingProfile)
                
                Button(action: { isEditing.toggle() }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.accentColor)
                        .background(Color(.systemBackground).clipShape(Circle()))
                        .offset(x: 5, y: 5)
                }
                .disabled(isUpdatingProfile)
            }

            VStack {
                if isEditing {
                    TextField("Name", text: $name)
                        .font(.title2).fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(user?.name ?? "No Name")
                        .font(.title2).fontWeight(.bold)
                }
                
                Text(user?.email ?? "no-email@example.com")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if isEditing {
                    VStack {
                        TextField("Phone Number", text: $phoneNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                        
                        TextField("Location / Area", text: $location)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}





#Preview {
    ProfileView()
        .environmentObject(UserManager())
}
