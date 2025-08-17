import Foundation
import Combine

@MainActor
class MarketPriceManager: ObservableObject {
    @Published var crops: [CropPrice] = []
    @Published var currentCropIndex: Int = 0
    @Published var currentCrop: CropPrice?
    
    private var timer: AnyCancellable?
    private let userDefaults = UserDefaults.standard
    private let cropsKey = "SavedCropPrices"
    private let currentIndexKey = "CurrentCropIndex"
    
    init() {
        loadSavedPrices()
        startPriceUpdates()
        updateCurrentCrop()
    }
    
    deinit {
        timer?.cancel()
    }
    
    // MARK: - Public Methods
    
    var currentMarketPrice: String {
        guard let crop = currentCrop else { return "₹0.00" }
        return crop.formattedPrice
    }
    
    var currentCropName: String {
        guard let crop = currentCrop else { return "Market Price" }
        return crop.name
    }
    
    // MARK: - Private Methods
    
    private func loadSavedPrices() {
        if let savedData = userDefaults.data(forKey: cropsKey),
           let savedCrops = try? JSONDecoder().decode([CropPrice].self, from: savedData) {
            // Use saved prices
            crops = savedCrops
            currentCropIndex = userDefaults.integer(forKey: currentIndexKey)
        } else {
            // Initialize with default prices
            crops = CropPrice.sampleCrops
            currentCropIndex = 0
            savePrices()
        }
        
        // Ensure index is within bounds
        if currentCropIndex >= crops.count {
            currentCropIndex = 0
        }
    }
    
    private func savePrices() {
        if let encoded = try? JSONEncoder().encode(crops) {
            userDefaults.set(encoded, forKey: cropsKey)
            userDefaults.set(currentCropIndex, forKey: currentIndexKey)
        }
    }
    
    private func startPriceUpdates() {
        // Update every 60 seconds (1 minute)
        timer = Timer.publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updatePricesAndRotate()
                }
            }
    }
    
    private func updatePricesAndRotate() {
        // Update all crop prices with fluctuations
        for i in 0..<crops.count {
            crops[i].updatePrice()
        }
        
        // Rotate to next crop
        currentCropIndex = (currentCropIndex + 1) % crops.count
        
        // Update current crop and save
        updateCurrentCrop()
        savePrices()
        
        print("🌾 Market prices updated. Now showing: \(currentCropName) - \(currentMarketPrice)")
    }
    
    private func updateCurrentCrop() {
        if !crops.isEmpty && currentCropIndex < crops.count {
            currentCrop = crops[currentCropIndex]
        }
    }
    
    // MARK: - Manual Update (for testing)
    
    func forceUpdate() {
        updatePricesAndRotate()
    }
}
