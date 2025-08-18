import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false
    @State private var showingSettings = false
    @State private var showingOrderHistory = false
    @StateObject private var orderManager: OrderManager
    
    // Use PhotosPickerItem for modern photo picking
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUpdatingProfile = false
    @State private var showSuccessMessage = false
    
    // Local state for text fields to enable editing
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var location: String = ""  // Changed from address to location to match User model
    
    init() {
        // Initialize OrderManager with empty string - will be updated in onAppear
        self._orderManager = StateObject(wrappedValue: OrderManager(userId: ""))
    }
    
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
                    
                    // Order History Section
                    Button(action: { showingOrderHistory = true }) {
                        HStack {
                            Image(systemName: "bag")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Order History")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                if let summary = orderManager.orderSummary {
                                    Text("\(summary.totalOrders) orders • \(summary.formattedTotalSpent) spent")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("View your past orders")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
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
            .sheet(isPresented: $showingOrderHistory) {
                OrderHistoryView(orderManager: orderManager)
            }
            .onAppear(perform: loadInitialUserData)
            .onChange(of: selectedPhotoItem, handlePhotoSelection)
            .onChange(of: isEditing) { oldValue, newValue in
                handleEditModeChange(from: oldValue, to: newValue)
            }
            .onChange(of: userManager.currentUser?.id) { newValue in
                if let userId = newValue {
                    orderManager.switchUser(to: userId)
                }
            }
        }
        .overlay(
            // Success message overlay
            VStack {
                if showSuccessMessage {
                    Text("Profile image updated successfully!")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: showSuccessMessage)
        )
    }
    
    private func loadInitialUserData() {
        if let user = userManager.currentUser {
            name = user.name
            phoneNumber = user.phoneNumber ?? ""
            location = user.location ?? ""
            // Initialize OrderManager with current user ID
            orderManager.switchUser(to: user.id)
        }
    }
    
    private func handleEditModeChange(from wasEditing: Bool, to isNowEditing: Bool) {
        // Clear any previous errors when entering edit mode
        if !wasEditing && isNowEditing {
            userManager.profileUpdateError = nil
            loadInitialUserData()
        } else if wasEditing && !isNowEditing {
            Task {
                await saveProfileChanges()
            }
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
            defer { 
                isUpdatingProfile = false
                // Reset the selected photo item to allow selecting the same image again
                selectedPhotoItem = nil
            }
            
            do {
                guard let data = try await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) else {
                    print("Failed to load image data.")
                    return
                }
                
                // Upload the profile image - UserManager will update the current user
                _ = try await userManager.uploadProfileImage(uiImage)
                
                // Show success message briefly
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessMessage = false
                }
                
            } catch {
                print("Error processing new profile image: \(error.localizedDescription)")
                // The error will be available in userManager.profileUpdateError for UI display
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
    @EnvironmentObject var userManager: UserManager
    @State private var showingErrorAlert = false
    @State private var imageRefreshId = UUID()

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Group {
                        if let profileImage = user?.profileImage, let url = URL(string: profileImage) {
                            // Add cache busting parameter to force refresh
                            let cacheBustingUrl = URL(string: "\(profileImage)?v=\(imageRefreshId.uuidString)")
                            AsyncImage(url: cacheBustingUrl ?? url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .id(imageRefreshId) // Force refresh when imageRefreshId changes
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
        .alert("Upload Error", isPresented: $showingErrorAlert) {
            Button("OK") {
                userManager.profileUpdateError = nil
            }
        } message: {
            Text(userManager.profileUpdateError ?? "An unknown error occurred")
        }
        .onChange(of: userManager.profileUpdateError) { oldValue, newValue in
            if newValue != nil {
                showingErrorAlert = true
            }
        }
        .onChange(of: user?.profileImage) { oldValue, newValue in
            // Force image refresh when profile image URL changes
            if oldValue != newValue && newValue != nil {
                imageRefreshId = UUID()
            }
        }
    }
}





#Preview {
    ProfileView()
        .environmentObject(UserManager())
}
