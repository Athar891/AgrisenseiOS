//
//  CropDetailView.swift
//  Agrisense
//
//  Created by Athar Reza on 13/08/25.
//

import SwiftUI
import PhotosUI

struct CropDetailView: View {
    let crop: Crop
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with crop image
                CropImageHeader(crop: crop)
                
                // Basic Information
                CropBasicInfoSection(crop: crop)
                
                // Health and Growth Status
                CropStatusSection(crop: crop)
                
                // Timeline and Progress
                CropTimelineSection(crop: crop)
                
                // Notes section
                if let notes = crop.notes, !notes.isEmpty {
                    CropNotesSection(notes: notes)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(crop.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditCropView(crop: crop)
        }
    }
}

struct CropImageHeader: View {
    let crop: Crop
    
    var body: some View {
        VStack(spacing: 16) {
            if let imageUrl = crop.cropImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(16)
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                    .overlay {
                        VStack {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            Text(LocalizationManager.shared.localizedString(for: "no_image"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .cornerRadius(16)
            }
        }
    }
}

struct CropBasicInfoSection: View {
    let crop: Crop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: "basic_information"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(title: LocalizationManager.shared.localizedString(for: "field_location"), value: crop.fieldLocation, icon: "location.fill")
                InfoRow(title: LocalizationManager.shared.localizedString(for: "planted"), value: crop.plantingDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                InfoRow(title: LocalizationManager.shared.localizedString(for: "expected_harvest"), value: crop.expectedHarvestDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar.badge.clock")
                InfoRow(title: LocalizationManager.shared.localizedString(for: "days_since_planting"), value: "\(crop.daysSincePlanting) \(LocalizationManager.shared.localizedString(for: "days"))", icon: "clock.fill")
                
                if crop.daysUntilHarvest > 0 {
                    InfoRow(title: LocalizationManager.shared.localizedString(for: "days_until_harvest"), value: "\(crop.daysUntilHarvest) \(LocalizationManager.shared.localizedString(for: "days"))", icon: "timer")
                } else if crop.isOverdue {
                    InfoRow(title: LocalizationManager.shared.localizedString(for: "status"), value: LocalizationManager.shared.localizedString(for: "overdue_for_harvest"), icon: "exclamationmark.triangle.fill")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct CropStatusSection: View {
    let crop: Crop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: "current_status"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Growth Stage
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizationManager.shared.localizedString(for: "growth_stage"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 8) {
                            Image(systemName: crop.currentGrowthStage.icon)
                                .foregroundColor(.green)
                            Text(crop.currentGrowthStage.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Health Status
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localizedString(for: "health_status"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 12) {
                            ProgressView(value: crop.healthStatus.healthPercentage)
                                .frame(width: 100)
                                .tint(crop.healthStatus.color)
                            
                            Text(crop.healthStatus.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(crop.healthStatus.color)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(Int(crop.healthStatus.healthPercentage * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(crop.healthStatus.color)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct CropTimelineSection: View {
    let crop: Crop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: "progress_timeline"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ProgressView(value: crop.progressPercentage)
                    .frame(height: 8)
                    .tint(.green)
                
                HStack {
                    Text(LocalizationManager.shared.localizedString(for: "planted"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: LocalizationManager.shared.localizedString(for: "percent_complete"), Int(crop.progressPercentage * 100)))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Harvest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct CropNotesSection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: "notes"))
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct EditCropView: View {
    let crop: Crop
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @StateObject private var cropManager = CropManager()
    
    @State private var cropName: String
    @State private var plantingDate: Date
    @State private var harvestDate: Date
    @State private var currentGrowthStage: GrowthStage
    @State private var healthStatus: CropHealthStatus
    @State private var fieldLocation: String
    @State private var notes: String
    @State private var selectedImage: PhotosPickerItem?
    @State private var cropImage: UIImage?
    @State private var currentImageUrl: String?
    
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    init(crop: Crop) {
        self.crop = crop
        self._cropName = State(initialValue: crop.name)
        self._plantingDate = State(initialValue: crop.plantingDate)
        self._harvestDate = State(initialValue: crop.expectedHarvestDate)
        self._currentGrowthStage = State(initialValue: crop.currentGrowthStage)
        self._healthStatus = State(initialValue: crop.healthStatus)
        self._fieldLocation = State(initialValue: crop.fieldLocation)
        self._notes = State(initialValue: crop.notes ?? "")
        self._currentImageUrl = State(initialValue: crop.cropImage)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Crop Name", text: $cropName)
                    TextField("Field/Location", text: $fieldLocation)
                    DatePicker("Planting Date", selection: $plantingDate, displayedComponents: .date)
                    DatePicker("Expected Harvest Date", selection: $harvestDate, displayedComponents: .date)
                }
                
                Section(header: Text("Current Status")) {
                    Picker("Growth Stage", selection: $currentGrowthStage) {
                        ForEach(GrowthStage.allCases, id: \.self) { stage in
                            HStack {
                                Image(systemName: stage.icon)
                                Text(stage.displayName)
                            }
                            .tag(stage)
                        }
                    }
                    
                    Picker("Health Status", selection: $healthStatus) {
                        ForEach(CropHealthStatus.allCases, id: \.self) { status in
                            Text(status.displayName)
                                .tag(status)
                        }
                    }
                }
                
                Section(header: Text("Crop Image")) {
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        if let cropImage = cropImage {
                            Image(uiImage: cropImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(8)
                        } else if let imageUrl = currentImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(8)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .overlay {
                                        ProgressView()
                                    }
                                    .cornerRadius(8)
                            }
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text(LocalizationManager.shared.localizedString(for: "select_crop_image"))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text(LocalizationManager.shared.localizedString(for: "notes"))) {
                    TextField(LocalizationManager.shared.localizedString(for: "additional_notes_placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(LocalizationManager.shared.localizedString(for: "save_changes")) {
                        Task {
                            await updateCrop()
                        }
                    }
                    .disabled(cropName.isEmpty || fieldLocation.isEmpty || isLoading)
                    
                    Button(LocalizationManager.shared.localizedString(for: "delete_crop"), role: .destructive) {
                        showingDeleteAlert = true
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle(String(format: LocalizationManager.shared.localizedString(for: "edit_x"), crop.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImage) { _, newItem in
                Task {
                    if let newItem = newItem {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            cropImage = UIImage(data: data)
                        }
                    }
                }
            }
            .alert(LocalizationManager.shared.localizedString(for: "error"), isPresented: $showingAlert) {
                Button(LocalizationManager.shared.localizedString(for: "ok")) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Delete Crop", isPresented: $showingDeleteAlert) {
                Button(LocalizationManager.shared.localizedString(for: "delete"), role: .destructive) {
                    Task {
                        await deleteCrop()
                    }
                }
                Button(LocalizationManager.shared.localizedString(for: "cancel"), role: .cancel) { }
            } message: {
                Text(LocalizationManager.shared.localizedString(for: "delete_crop_confirmation"))
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Updating crop...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func updateCrop() async {
        guard let userId = userManager.currentUser?.id else {
                    alertMessage = LocalizationManager.shared.localizedString(for: "user_not_found_try_login")
            showingAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Upload new image if selected
            var imageUrl: String? = currentImageUrl
            if let cropImage = cropImage {
                imageUrl = try await cropManager.uploadCropImage(cropImage)
            }
            
            // Create updated crop
            var updatedCrop = crop
            updatedCrop.name = cropName
            updatedCrop.plantingDate = plantingDate
            updatedCrop.expectedHarvestDate = harvestDate
            updatedCrop.currentGrowthStage = currentGrowthStage
            updatedCrop.healthStatus = healthStatus
            updatedCrop.fieldLocation = fieldLocation
            updatedCrop.notes = notes.isEmpty ? nil : notes
            updatedCrop.cropImage = imageUrl
            updatedCrop.updatedAt = Date()
            
            // Update user's crops array
            guard var updatedUser = userManager.currentUser else { return }
            if let index = updatedUser.crops.firstIndex(where: { $0.id == crop.id }) {
                updatedUser.crops[index] = updatedCrop
            }
            
            // Save to Firestore
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            var cropsData: [[String: Any]] = []
            for cropItem in updatedUser.crops {
                if let jsonData = try? encoder.encode(cropItem),
                   let cropDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    cropsData.append(cropDict)
                }
            }
            
            try await userManager.db.collection("users").document(userId).setData([
                "crops": cropsData
            ], merge: true)
            
            // Update local user
            userManager.currentUser = updatedUser
            
            dismiss()
            } catch {
            alertMessage = String(format: LocalizationManager.shared.localizedString(for: "failed_update_crop"), error.localizedDescription)
            showingAlert = true
        }
        
        isLoading = false
    }
    
    private func deleteCrop() async {
        guard let userId = userManager.currentUser?.id else {
            alertMessage = "User not found. Please try logging in again."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Remove crop from user's crops array
            guard var updatedUser = userManager.currentUser else { return }
            updatedUser.crops.removeAll { $0.id == crop.id }
            
            // Save to Firestore
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            var cropsData: [[String: Any]] = []
            for cropItem in updatedUser.crops {
                if let jsonData = try? encoder.encode(cropItem),
                   let cropDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    cropsData.append(cropDict)
                }
            }
            
            try await userManager.db.collection("users").document(userId).setData([
                "crops": cropsData
            ], merge: true)
            
            // Update local user
            userManager.currentUser = updatedUser
            
            dismiss()
            } catch {
            alertMessage = String(format: LocalizationManager.shared.localizedString(for: "failed_delete_crop"), error.localizedDescription)
            showingAlert = true
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationView {
        CropDetailView(crop: Crop(
            name: "Tomatoes",
            plantingDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            expectedHarvestDate: Date().addingTimeInterval(60 * 24 * 60 * 60),
            currentGrowthStage: .vegetative,
            healthStatus: .good,
            fieldLocation: "Field A - North Section",
            notes: "Looking healthy, regular watering schedule maintained."
        ))
    }
    .environmentObject(UserManager())
}
