import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false
    @State private var showingSettings = false
    @State private var showingOrderHistory = false
    @State private var showingLanguageSheet = false
    @StateObject private var orderManager: OrderManager
    
    // Use PhotosPickerItem for modern photo picking
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUpdatingProfile = false
    @State private var showSuccessMessage = false
    @State private var compressedPreviewData: Data?
    @State private var compressedPreviewImage: UIImage?
    @State private var compressedPreviewSizeKB: Int?
    @State private var showingPreviewSheet = false
    
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
                    
                    // Language Settings
                    Button(action: { showingLanguageSheet = true }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizationManager.shared.localizedString(for: "language_settings"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(LocalizationManager.shared.localizedString(for: "select_language"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
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
            .navigationTitle(LocalizationManager.shared.localizedString(for: "profile_title"))
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
            .sheet(isPresented: $showingPreviewSheet) {
                ProfileImagePreviewSheet(
                    compressedPreviewImage: $compressedPreviewImage,
                    compressedPreviewSizeKB: $compressedPreviewSizeKB,
                    isUpdatingProfile: $isUpdatingProfile,
                    showingPreviewSheet: $showingPreviewSheet,
                    onCancel: {
                        compressedPreviewData = nil
                        compressedPreviewImage = nil
                        compressedPreviewSizeKB = nil
                        showingPreviewSheet = false
                    },
                    onUpload: {
                        confirmCompressedUpload()
                    }
                )
            }
            .sheet(isPresented: $showingLanguageSheet) {
                LanguageSelectionSheet()
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
            // Load selected image data
            isUpdatingProfile = true
            defer {
                isUpdatingProfile = false
                // Reset the selected photo item so the same image can be reselected later
                selectedPhotoItem = nil
            }

            do {
                guard let data = try await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) else {
                    print("Failed to load image data.")
                    return
                }

                // Create compressed preview data using the same target (5 MB)
                if let compressed = ImageCompressor.compressImageData(uiImage, maxSizeKB: 5 * 1024) {
                    compressedPreviewData = compressed
                    compressedPreviewImage = UIImage(data: compressed)
                    compressedPreviewSizeKB = compressed.count / 1024
                    showingPreviewSheet = true
                } else {
                    // Fall back to direct upload if compression fails
                    _ = try await userManager.uploadProfileImage(uiImage)
                    showSuccessMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccessMessage = false
                    }
                }

            } catch {
                print("Error processing new profile image: \(error.localizedDescription)")
            }
        }
    }

    // Called when the user confirms upload from preview sheet
    private func confirmCompressedUpload() {
        guard let data = compressedPreviewData, let uiImage = UIImage(data: data) else { return }

        Task {
            isUpdatingProfile = true
            defer {
                isUpdatingProfile = false
                compressedPreviewData = nil
                compressedPreviewImage = nil
                compressedPreviewSizeKB = nil
                showingPreviewSheet = false
            }

            do {
                _ = try await userManager.uploadProfileImage(uiImage)
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessMessage = false
                }
            } catch {
                print("Error uploading compressed image: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Language Selection Sheet
struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCode: String? = LocalizationManager.shared.currentLanguageCode

    var body: some View {
        NavigationView {
            List {
                ForEach(LocalizationManager.shared.availableLanguages(), id: \.code) { item in
                    Button(action: {
                        selectedCode = item.code
                        LocalizationManager.shared.setLanguage(code: item.code)
                    }) {
                        HStack {
                            Text(item.nativeName)
                                .font(.body)

                            Spacer()

                            if selectedCode == item.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }

                // Reset to system language
                Button(action: {
                    selectedCode = nil
                    LocalizationManager.shared.setLanguage(code: nil)
                }) {
                    HStack {
                        Text("System Default")
                        Spacer()
                        if selectedCode == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "select_language"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
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



// MARK: - Profile Image Preview Sheet
struct ProfileImagePreviewSheet: View {
    @Binding var compressedPreviewImage: UIImage?
    @Binding var compressedPreviewSizeKB: Int?
    @Binding var isUpdatingProfile: Bool
    @Binding var showingPreviewSheet: Bool
    let onCancel: () -> Void
    let onUpload: () -> Void
    
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        // Title and subtitle
                        VStack(spacing: 4) {
                            Text("Review your photo before uploading")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                        
                        // Size info card
                        if let sizeKB = compressedPreviewSizeKB {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("Compressed size: \(formatFileSize(sizeKB))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                // Quality indicator
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(sizeKB > 1024 ? Color.orange : Color.green)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(sizeKB > 1024 ? "Good" : "Excellent")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(sizeKB > 1024 ? .orange : .green)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Image preview area
                    ZStack {
                        // Background pattern
                        Rectangle()
                            .fill(Color(.tertiarySystemBackground))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.3))
                            )
                        
                        // Image with zoom and pan capabilities
                        if let image = compressedPreviewImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(imageScale)
                                .offset(imageOffset)
                                .gesture(
                                    SimultaneousGesture(
                                        // Magnification gesture
                                        MagnificationGesture()
                                            .onChanged { value in
                                                imageScale = max(0.5, min(3.0, value))
                                            },
                                        
                                        // Drag gesture
                                        DragGesture()
                                            .onChanged { value in
                                                isDragging = true
                                                imageOffset = value.translation
                                            }
                                            .onEnded { _ in
                                                isDragging = false
                                                withAnimation(.spring()) {
                                                    // Reset if dragged too far
                                                    if abs(imageOffset.width) > 100 || abs(imageOffset.height) > 100 {
                                                        imageOffset = .zero
                                                    }
                                                }
                                            }
                                    )
                                )
                                .animation(.easeInOut(duration: 0.2), value: isDragging)
                        } else {
                            // Loading state
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                
                                Text("Processing image...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Zoom controls and info
                    if compressedPreviewImage != nil {
                        VStack(spacing: 12) {
                            // Zoom controls
                            HStack(spacing: 20) {
                                Button(action: { 
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        imageScale = max(0.5, imageScale - 0.2)
                                    }
                                }) {
                                    Image(systemName: "minus.magnifyingglass")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(Int(imageScale * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40)
                                
                                Button(action: { 
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        imageScale = min(3.0, imageScale + 0.2)
                                    }
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        imageScale = 1.0
                                        imageOffset = .zero
                                    }
                                }) {
                                    Text("Reset")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            // Gesture hint
                            Text("Pinch to zoom • Drag to reposition")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Primary upload button
                        Button(action: onUpload) {
                            HStack(spacing: 8) {
                                if isUpdatingProfile {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "icloud.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Text(isUpdatingProfile ? "Uploading..." : "Upload Photo")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isUpdatingProfile || compressedPreviewImage == nil)
                        .animation(.easeInOut(duration: 0.2), value: isUpdatingProfile)
                        
                        // Secondary cancel button
                        Button(action: onCancel) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.tertiarySystemBackground))
                                .foregroundColor(.secondary)
                                .cornerRadius(8)
                        }
                        .disabled(isUpdatingProfile)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isUpdatingProfile)
    }
    
    private func formatFileSize(_ sizeKB: Int) -> String {
        if sizeKB < 1024 {
            return "\(sizeKB) KB"
        } else {
            let sizeMB = Double(sizeKB) / 1024.0
            return String(format: "%.1f MB", sizeMB)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
}
