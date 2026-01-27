//
//  AddCropViewModel.swift
//  Agrisense
//
//  Created on 26/01/2026.
//

import Foundation
import CoreLocation
import UIKit

// MARK: - CropType Enum
enum CropType: String, CaseIterable, Codable {
    // Cereals & Grains
    case wheat = "Wheat"
    case rice = "Rice"
    case corn = "Corn"
    case barley = "Barley"
    case millet = "Millet"
    case sorghum = "Sorghum"
    case oats = "Oats"
    
    // Pulses & Legumes
    case chickpea = "Chickpea"
    case lentils = "Lentils"
    case peas = "Peas"
    case beans = "Beans"
    case soybeans = "Soybeans"
    
    // Oilseeds
    case peanuts = "Peanuts"
    case sunflower = "Sunflower"
    case mustard = "Mustard"
    case sesame = "Sesame"
    
    // Vegetables - Fruiting
    case tomato = "Tomato"
    case eggplant = "Eggplant"
    case pepper = "Pepper"
    case cucumber = "Cucumber"
    
    // Vegetables - Root & Tuber
    case potato = "Potato"
    case sweetPotato = "Sweet Potato"
    case carrot = "Carrot"
    case radish = "Radish"
    case onion = "Onion"
    case garlic = "Garlic"
    
    // Vegetables - Leafy & Cole Crops
    case cabbage = "Cabbage"
    case cauliflower = "Cauliflower"
    case spinach = "Spinach"
    case lettuce = "Lettuce"
    
    // Cash Crops
    case cotton = "Cotton"
    case sugarcane = "Sugarcane"
    case tobacco = "Tobacco"
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        // Cereals & Grains
        case .wheat: return "🌾"
        case .rice: return "🍚"
        case .corn: return "🌽"
        case .barley: return "🌾"
        case .millet: return "🌾"
        case .sorghum: return "🌾"
        case .oats: return "🌾"
        
        // Pulses & Legumes
        case .chickpea: return "🫘"
        case .lentils: return "🫘"
        case .peas: return "🫛"
        case .beans: return "🫘"
        case .soybeans: return "🫘"
        
        // Oilseeds
        case .peanuts: return "🥜"
        case .sunflower: return "🌻"
        case .mustard: return "🌿"
        case .sesame: return "🌱"
        
        // Vegetables - Fruiting
        case .tomato: return "🍅"
        case .eggplant: return "🍆"
        case .pepper: return "🌶️"
        case .cucumber: return "🥒"
        
        // Vegetables - Root & Tuber
        case .potato: return "🥔"
        case .sweetPotato: return "🍠"
        case .carrot: return "🥕"
        case .radish: return "🌱"
        case .onion: return "🧅"
        case .garlic: return "🧄"
        
        // Vegetables - Leafy & Cole Crops
        case .cabbage: return "🥬"
        case .cauliflower: return "🥦"
        case .spinach: return "🥬"
        case .lettuce: return "🥬"
        
        // Cash Crops
        case .cotton: return "🌱"
        case .sugarcane: return "🎋"
        case .tobacco: return "🌿"
        }
    }
    
    /// Growth duration in days (based on agricultural research averages)
    var growthDurationDays: Int {
        switch self {
        // Cereals & Grains
        case .wheat: return 135      // 120-150 days
        case .rice: return 120       // 90-150 days
        case .corn: return 80        // 60-100 days
        case .barley: return 105     // 90-120 days
        case .millet: return 75      // 60-90 days
        case .sorghum: return 105    // 90-120 days
        case .oats: return 90        // 80-100 days
        
        // Pulses & Legumes
        case .chickpea: return 100   // 90-120 days
        case .lentils: return 95     // 80-110 days
        case .peas: return 65        // 60-70 days
        case .beans: return 55       // 50-60 days
        case .soybeans: return 120   // 90-150 days
        
        // Oilseeds
        case .peanuts: return 125    // 100-150 days
        case .sunflower: return 85   // 70-100 days
        case .mustard: return 90     // 75-100 days
        case .sesame: return 105     // 90-120 days
        
        // Vegetables - Fruiting
        case .tomato: return 75      // 60-85 days
        case .eggplant: return 80    // 60-90 days
        case .pepper: return 75      // 60-90 days
        case .cucumber: return 60    // 50-70 days
        
        // Vegetables - Root & Tuber
        case .potato: return 90      // 70-120 days
        case .sweetPotato: return 120 // 90-150 days
        case .carrot: return 75      // 70-80 days
        case .radish: return 28      // 25-30 days
        case .onion: return 100      // 90-120 days
        case .garlic: return 165     // 150-180 days
        
        // Vegetables - Leafy & Cole Crops
        case .cabbage: return 75     // 60-90 days
        case .cauliflower: return 70 // 55-80 days
        case .spinach: return 45     // 40-50 days
        case .lettuce: return 50     // 45-55 days
        
        // Cash Crops
        case .cotton: return 165     // 150-180 days
        case .sugarcane: return 330  // 300-365 days
        case .tobacco: return 75     // 60-90 days
        }
    }
}

// MARK: - Plot Size Unit Enum
enum PlotSizeUnit: String, CaseIterable, Codable {
    case acres = "Acres"
    case hectares = "Hectares"
    
    var displayName: String {
        rawValue
    }
    
    var abbreviation: String {
        switch self {
        case .acres: return "ac"
        case .hectares: return "ha"
        }
    }
    
    /// Convert to hectares (standard unit)
    func toHectares(_ value: Double) -> Double {
        switch self {
        case .acres: return value * 0.404686
        case .hectares: return value
        }
    }
}

// MARK: - Location Data
struct LocationData {
    let latitude: Double
    let longitude: Double
    let address: String
    
    var displayString: String {
        address.isEmpty ? "\(latitude), \(longitude)" : address
    }
    
    var coordinatesString: String {
        "\(latitude), \(longitude)"
    }
}

// MARK: - AddCropViewModel
@MainActor
class AddCropViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    // Crop Selection
    @Published var selectedCropType: CropType = .wheat
    
    // Dates
    @Published var plantingDate: Date = Date()
    @Published var expectedHarvestDate: Date = Date()
    
    // Location
    @Published var locationData: LocationData?
    @Published var isGettingLocation = false
    @Published var locationError: String?
    
    // Plot Size
    @Published var plotSize: String = ""
    @Published var plotSizeUnit: PlotSizeUnit = .acres
    
    // Existing fields
    @Published var currentGrowthStage: GrowthStage = .seeding
    @Published var healthStatus: CropHealthStatus = .good
    @Published var notes: String = ""
    @Published var cropImage: UIImage?
    
    // Loading & Error States
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Dependencies
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    private let geocoder = CLGeocoder()
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        // Must have location data
        guard locationData != nil else { return false }
        
        // Must have valid plot size
        guard !plotSize.isEmpty,
              let plotValue = Double(plotSize),
              plotValue > 0 else { return false }
        
        return true
    }
    
    var plotSizeInHectares: Double? {
        guard let value = Double(plotSize) else { return nil }
        return plotSizeUnit.toHectares(value)
    }
    
    var formattedPlotSize: String {
        guard let value = Double(plotSize) else { return "" }
        return "\(value) \(plotSizeUnit.abbreviation)"
    }
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        updateExpectedHarvestDate()
    }
    
    // MARK: - Date Logic
    
    func updateExpectedHarvestDate() {
        let calendar = Calendar.current
        let daysToAdd = selectedCropType.growthDurationDays
        if let newHarvestDate = calendar.date(byAdding: .day, value: daysToAdd, to: plantingDate) {
            expectedHarvestDate = newHarvestDate
        }
    }
    
    func onPlantingDateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateExpectedHarvestDate()
        }
    }
    
    func onCropTypeChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateExpectedHarvestDate()
        }
    }
    
    // MARK: - Location Methods
    
    func requestLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = "Location services are disabled. Please enable them in Settings."
            return
        }
        
        let authStatus = locationManager.authorizationStatus
        
        switch authStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Will be called again after user responds
            return
            
        case .restricted, .denied:
            locationError = "Location access denied. Please enable location permissions in Settings."
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            fetchCurrentLocation()
            
        @unknown default:
            locationError = "Unknown location authorization status."
        }
    }
    
    private func fetchCurrentLocation() {
        isGettingLocation = true
        locationError = nil
        
        locationManager.requestLocation()
        
        // Use a simple callback-based approach
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            
            if let location = self.locationManager.location {
                self.processLocation(location)
            } else {
                self.isGettingLocation = false
                self.locationError = "Unable to get your location. Please try again."
            }
        }
    }
    
    private func processLocation(_ location: CLLocation) {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        // Reverse geocode to get address
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            self.isGettingLocation = false
            
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                // Still save coordinates even if geocoding fails
                self.locationData = LocationData(
                    latitude: latitude,
                    longitude: longitude,
                    address: "Location acquired"
                )
                return
            }
            
            // Extract address from placemark
            let address = self.formatAddress(from: placemarks?.first)
            
            self.locationData = LocationData(
                latitude: latitude,
                longitude: longitude,
                address: address
            )
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark?) -> String {
        guard let placemark = placemark else { return "Unknown Location" }
        
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.isEmpty ? "Location acquired" : components.joined(separator: ", ")
    }
    
    func clearLocation() {
        locationData = nil
        locationError = nil
    }
    
    // MARK: - Validation
    
    func validateForm() -> String? {
        // Check location
        guard locationData != nil else {
            return "Please set your field location using GPS."
        }
        
        // Check plot size
        guard !plotSize.isEmpty else {
            return "Please enter the plot size."
        }
        
        guard let plotValue = Double(plotSize), plotValue > 0 else {
            return "Please enter a valid plot size greater than 0."
        }
        
        // Validate planting date is not in the future by more than a day
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        if plantingDate > tomorrow {
            return "Planting date cannot be more than 1 day in the future."
        }
        
        return nil
    }
    
    // MARK: - Crop Creation
    
    func createCrop() -> Crop? {
        guard let location = locationData else { return nil }
        
        // Create field location string with coordinates
        let fieldLocationString = "\(location.displayString) (\(location.coordinatesString))"
        
        let crop = Crop(
            name: "\(selectedCropType.icon) \(selectedCropType.displayName)",
            plantingDate: plantingDate,
            expectedHarvestDate: expectedHarvestDate,
            currentGrowthStage: currentGrowthStage,
            healthStatus: healthStatus,
            fieldLocation: fieldLocationString,
            notes: notes.isEmpty ? "Plot Size: \(formattedPlotSize)" : "Plot Size: \(formattedPlotSize)\n\(notes)",
            cropImage: nil // Will be set separately after upload
        )
        
        return crop
    }
    
    // MARK: - Reset
    
    func reset() {
        selectedCropType = .wheat
        plantingDate = Date()
        updateExpectedHarvestDate()
        locationData = nil
        plotSize = ""
        plotSizeUnit = .acres
        currentGrowthStage = .seeding
        healthStatus = .good
        notes = ""
        cropImage = nil
        errorMessage = nil
        locationError = nil
    }
}

// MARK: - CLLocationManagerDelegate Extension
extension AddCropViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Location is already handled in fetchCurrentLocation with a timeout
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isGettingLocation = false
            self.locationError = "Failed to get location: \(error.localizedDescription)"
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                // Permission granted, try to get location
                self.fetchCurrentLocation()
            }
        }
    }
}
