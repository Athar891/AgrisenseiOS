//
//  Crop.swift
//  Agrisense
//
//  Created by Athar Reza on 13/08/25.
//

import Foundation
import SwiftUI

enum GrowthStage: String, CaseIterable, Codable {
    case seeding = "seeding"
    case germination = "germination"
    case vegetative = "vegetative"
    case flowering = "flowering"
    case fruiting = "fruiting"
    case maturity = "maturity"
    case harvest = "harvest"
    
    var displayName: String {
        switch self {
        case .seeding:
            return "Seeding"
        case .germination:
            return "Germination"
        case .vegetative:
            return "Vegetative Growth"
        case .flowering:
            return "Flowering"
        case .fruiting:
            return "Fruiting"
        case .maturity:
            return "Maturity"
        case .harvest:
            return "Ready for Harvest"
        }
    }
    
    var icon: String {
        switch self {
        case .seeding:
            return "dot.circle"
        case .germination:
            return "leaf"
        case .vegetative:
            return "leaf.fill"
        case .flowering:
            return "flower"
        case .fruiting:
            return "circle.fill"
        case .maturity:
            return "checkmark.circle"
        case .harvest:
            return "checkmark.circle.fill"
        }
    }
}

enum CropHealthStatus: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .critical:
            return "Critical"
        }
    }
    
    var healthPercentage: Double {
        switch self {
        case .excellent:
            return 0.95
        case .good:
            return 0.80
        case .fair:
            return 0.65
        case .poor:
            return 0.40
        case .critical:
            return 0.20
        }
    }
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .critical:
            return .red
        }
    }
}

struct Crop: Codable, Identifiable {
    let id: String
    var name: String
    var plantingDate: Date
    var expectedHarvestDate: Date
    var currentGrowthStage: GrowthStage
    var healthStatus: CropHealthStatus
    var fieldLocation: String
    var notes: String?
    var cropImage: String? // Cloudinary URL
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        plantingDate: Date,
        expectedHarvestDate: Date,
        currentGrowthStage: GrowthStage = .seeding,
        healthStatus: CropHealthStatus = .good,
        fieldLocation: String,
        notes: String? = nil,
        cropImage: String? = nil
    ) {
        self.id = id
        self.name = name
        self.plantingDate = plantingDate
        self.expectedHarvestDate = expectedHarvestDate
        self.currentGrowthStage = currentGrowthStage
        self.healthStatus = healthStatus
        self.fieldLocation = fieldLocation
        self.notes = notes
        self.cropImage = cropImage
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed properties for dashboard display
    var daysUntilHarvest: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expectedHarvestDate).day ?? 0
    }
    
    var daysSincePlanting: Int {
        Calendar.current.dateComponents([.day], from: plantingDate, to: Date()).day ?? 0
    }
    
    var isOverdue: Bool {
        Date() > expectedHarvestDate
    }
    
    var progressPercentage: Double {
        let totalDays = Calendar.current.dateComponents([.day], from: plantingDate, to: expectedHarvestDate).day ?? 1
        let daysPassed = daysSincePlanting
        return min(Double(daysPassed) / Double(totalDays), 1.0)
    }
}
