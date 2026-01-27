import SwiftUI
import PhotosUI
import UIKit
import CoreLocation

@MainActor
struct AddCropView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var cropManager = CropManager()
    @StateObject private var viewModel = AddCropViewModel()
    
    @State private var selectedImage: PhotosPickerItem?
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Crop Selection Section
                Section(header: Text("Smart Crop Selection")) {
                    Picker("Crop Type", selection: $viewModel.selectedCropType) {
                        ForEach(CropType.allCases, id: \.self) { cropType in
                            Text("\(cropType.icon) \(cropType.displayName)")
                                .tag(cropType)
                        }
                    }
                    .onChange(of: viewModel.selectedCropType) { oldValue, newValue in
                        if oldValue != newValue {
                            viewModel.onCropTypeChanged()
                        }
                    }
                    
                    HStack {
                        Label("Growth Duration", systemImage: "clock")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.selectedCropType.growthDurationDays) days")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                // MARK: - Dates Section
                Section(header: Text("Planting & Harvest Schedule")) {
                    DatePicker(
                        "Planting Date",
                        selection: $viewModel.plantingDate,
                        in: ...Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                        displayedComponents: .date
                    )
                    .onChange(of: viewModel.plantingDate) { oldValue, newValue in
                        if oldValue != newValue {
                            viewModel.onPlantingDateChanged()
                        }
                    }
                    
                    HStack {
                        Text("Expected Harvest")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.expectedHarvestDate, style: .date)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Location Section
                Section(header: Text("📍 Field Location (GPS Required)")) {
                    if let location = viewModel.locationData {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.green)
                                Text(location.displayString)
                                    .font(.body)
                                Spacer()
                                Button(action: {
                                    viewModel.clearLocation()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Text(location.coordinatesString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 24)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: {
                            viewModel.requestLocation()
                        }) {
                            HStack {
                                if viewModel.isGettingLocation {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(.blue)
                                }
                                
                                Text(viewModel.isGettingLocation ? "Getting Location..." : "📍 Use Current GPS Location")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                        .disabled(viewModel.isGettingLocation)
                    }
                    
                    if let error = viewModel.locationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Plot Size Section
                Section(header: Text("🌾 Plot Size (For Fertilizer Calculation)")) {
                    HStack {
                        TextField("Enter size", text: $viewModel.plotSize)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: .infinity)
                        
                        Picker("", selection: $viewModel.plotSizeUnit) {
                            ForEach(PlotSizeUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    if let hectares = viewModel.plotSizeInHectares {
                        HStack {
                            Text("Equivalent")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f hectares", hectares))
                                .foregroundColor(.primary)
                                .font(.caption)
                        }
                    }
                }

                // MARK: - Current Status Section
                Section(header: Text(localizationManager.localizedString(for: "current_status"))) {
                    Picker(localizationManager.localizedString(for: "growth_stage"), selection: $viewModel.currentGrowthStage) {
                        ForEach(GrowthStage.allCases, id: \.self) { stage in
                            HStack {
                                Image(systemName: stage.icon)
                                Text(stage.displayName)
                            }
                            .tag(stage)
                        }
                    }
                    
                    Picker("Health Status", selection: $viewModel.healthStatus) {
                        ForEach(CropHealthStatus.allCases, id: \.self) { status in
                            Text(status.displayName)
                                .tag(status)
                        }
                    }
                }
                
                // MARK: - Crop Image Section (Optional)
                Section(header: Text(localizationManager.localizedString(for: "crop_image_optional"))) {
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        if let cropImage = viewModel.cropImage {
                            Image(uiImage: cropImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text(localizationManager.localizedString(for: "select_crop_image"))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // MARK: - Notes Section
                Section(header: Text(localizationManager.localizedString(for: "notes_optional"))) {
                    TextField(localizationManager.localizedString(for: "additional_notes_placeholder"), text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // MARK: - Action Button
                Section {
                    Button(localizationManager.localizedString(for: "add_crop")) {
                        Task {
                            await addCrop()
                        }
                    }
                    .disabled(!viewModel.isFormValid || isLoading)
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "add_new_crop"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImage) { _, newItem in
                Task {
                    if let newItem = newItem {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            viewModel.cropImage = UIImage(data: data)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Adding crop...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func addCrop() async {
        // Validate form
        if let validationError = viewModel.validateForm() {
            alertMessage = validationError
            showingAlert = true
            return
        }
        
        guard let userId = userManager.currentUser?.id else {
            alertMessage = "User not found. Please try logging in again."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Upload image if selected
            var imageUrl: String?
            if let cropImage = viewModel.cropImage {
                imageUrl = try await cropManager.uploadCropImage(cropImage, userId: userId)
            }
            
            // Create new crop from ViewModel
            guard var newCrop = viewModel.createCrop() else {
                throw NSError(domain: "AddCropView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create crop data"])
            }
            
            // Set image URL if uploaded
            if let imageUrl = imageUrl {
                newCrop.cropImage = imageUrl
            }
            
            // Add crop to user's crops
            var updatedUser = userManager.currentUser!
            updatedUser.crops.append(newCrop)
            
            // Save to Firestore
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            var cropsData: [[String: Any]] = []
            for crop in updatedUser.crops {
                if let jsonData = try? encoder.encode(crop),
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
            alertMessage = "Failed to add crop: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isLoading = false
    }
}

#Preview {
    AddCropView()
        .environmentObject(UserManager())
        .environmentObject(LocalizationManager.shared)
}
