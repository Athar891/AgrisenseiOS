import SwiftUI
import PhotosUI

struct AddCropView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @StateObject private var cropManager = CropManager()
    
    @State private var cropName = ""
    @State private var plantingDate = Date()
    @State private var harvestDate = Date().addingTimeInterval(60 * 60 * 24 * 90) // 90 days from now
    @State private var currentGrowthStage = GrowthStage.seeding
    @State private var healthStatus = CropHealthStatus.good
    @State private var fieldLocation = ""
    @State private var notes = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var cropImage: UIImage?
    
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

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
                
                Section(header: Text("Crop Image (Optional)")) {
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
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Select Crop Image")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Additional notes about this crop...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Add Crop") {
                        Task {
                            await addCrop()
                        }
                    }
                    .disabled(cropName.isEmpty || fieldLocation.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add New Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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
        guard let userId = userManager.currentUser?.id else {
            alertMessage = "User not found. Please try logging in again."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Upload image if selected
            var imageUrl: String?
            if let cropImage = cropImage {
                imageUrl = try await cropManager.uploadCropImage(cropImage)
            }
            
            // Create new crop
            let newCrop = Crop(
                name: cropName,
                plantingDate: plantingDate,
                expectedHarvestDate: harvestDate,
                currentGrowthStage: currentGrowthStage,
                healthStatus: healthStatus,
                fieldLocation: fieldLocation,
                notes: notes.isEmpty ? nil : notes,
                cropImage: imageUrl
            )
            
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
            
            try await userManager.db.collection("users").document(userId).updateData([
                "crops": cropsData
            ])
            
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
}
