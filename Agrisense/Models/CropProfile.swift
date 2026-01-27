//
//  CropProfile.swift
//  Agrisense
//
//  Created on 26/01/2026.
//

import Foundation
import SwiftData

// MARK: - NPK Ratio Model
@Model
class NPKRatio: Codable {
    var nitrogen: Double
    var phosphorus: Double
    var potassium: Double
    
    init(nitrogen: Double, phosphorus: Double, potassium: Double) {
        self.nitrogen = nitrogen
        self.phosphorus = phosphorus
        self.potassium = potassium
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case nitrogen, phosphorus, potassium
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nitrogen = try container.decode(Double.self, forKey: .nitrogen)
        phosphorus = try container.decode(Double.self, forKey: .phosphorus)
        potassium = try container.decode(Double.self, forKey: .potassium)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nitrogen, forKey: .nitrogen)
        try container.encode(phosphorus, forKey: .phosphorus)
        try container.encode(potassium, forKey: .potassium)
    }
    
    var formattedRatio: String {
        "\(Int(nitrogen))-\(Int(phosphorus))-\(Int(potassium))"
    }
}

// MARK: - Fertilizer Input Model
@Model
class FertilizerInput: Codable {
    var id: UUID
    var name: String
    var npkRatio: NPKRatio
    var applicationRate: Double // kg per hectare
    var applicationMethod: String // e.g., "Broadcast", "Drip", "Foliar"
    var notes: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        npkRatio: NPKRatio,
        applicationRate: Double,
        applicationMethod: String,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.npkRatio = npkRatio
        self.applicationRate = applicationRate
        self.applicationMethod = applicationMethod
        self.notes = notes
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, npkRatio, applicationRate, applicationMethod, notes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        npkRatio = try container.decode(NPKRatio.self, forKey: .npkRatio)
        applicationRate = try container.decode(Double.self, forKey: .applicationRate)
        applicationMethod = try container.decode(String.self, forKey: .applicationMethod)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(npkRatio, forKey: .npkRatio)
        try container.encode(applicationRate, forKey: .applicationRate)
        try container.encode(applicationMethod, forKey: .applicationMethod)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - Irrigation Frequency Model
@Model
class IrrigationFrequency: Codable {
    var frequencyInDays: Int
    var waterAmountPerSession: Double // liters per plant or cubic meters per hectare
    var method: String // e.g., "Drip", "Sprinkler", "Flood"
    var timeOfDay: String? // e.g., "Early Morning", "Evening"
    
    init(
        frequencyInDays: Int,
        waterAmountPerSession: Double,
        method: String,
        timeOfDay: String? = nil
    ) {
        self.frequencyInDays = frequencyInDays
        self.waterAmountPerSession = waterAmountPerSession
        self.method = method
        self.timeOfDay = timeOfDay
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case frequencyInDays, waterAmountPerSession, method, timeOfDay
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frequencyInDays = try container.decode(Int.self, forKey: .frequencyInDays)
        waterAmountPerSession = try container.decode(Double.self, forKey: .waterAmountPerSession)
        method = try container.decode(String.self, forKey: .method)
        timeOfDay = try container.decodeIfPresent(String.self, forKey: .timeOfDay)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frequencyInDays, forKey: .frequencyInDays)
        try container.encode(waterAmountPerSession, forKey: .waterAmountPerSession)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(timeOfDay, forKey: .timeOfDay)
    }
    
    var description: String {
        "Every \(frequencyInDays) day(s) - \(waterAmountPerSession)L via \(method)"
    }
}

// MARK: - Pest Vulnerability Model
@Model
class PestVulnerability: Codable {
    var id: UUID
    var pestName: String
    var scientificName: String?
    var severity: PestSeverity
    var symptoms: [String]
    var organicControlMethods: [String]
    var chemicalControlMethods: [String]
    var preventiveMeasures: [String]
    
    init(
        id: UUID = UUID(),
        pestName: String,
        scientificName: String? = nil,
        severity: PestSeverity,
        symptoms: [String] = [],
        organicControlMethods: [String] = [],
        chemicalControlMethods: [String] = [],
        preventiveMeasures: [String] = []
    ) {
        self.id = id
        self.pestName = pestName
        self.scientificName = scientificName
        self.severity = severity
        self.symptoms = symptoms
        self.organicControlMethods = organicControlMethods
        self.chemicalControlMethods = chemicalControlMethods
        self.preventiveMeasures = preventiveMeasures
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, pestName, scientificName, severity, symptoms
        case organicControlMethods, chemicalControlMethods, preventiveMeasures
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pestName = try container.decode(String.self, forKey: .pestName)
        scientificName = try container.decodeIfPresent(String.self, forKey: .scientificName)
        severity = try container.decode(PestSeverity.self, forKey: .severity)
        symptoms = try container.decode([String].self, forKey: .symptoms)
        organicControlMethods = try container.decode([String].self, forKey: .organicControlMethods)
        chemicalControlMethods = try container.decode([String].self, forKey: .chemicalControlMethods)
        preventiveMeasures = try container.decode([String].self, forKey: .preventiveMeasures)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pestName, forKey: .pestName)
        try container.encodeIfPresent(scientificName, forKey: .scientificName)
        try container.encode(severity, forKey: .severity)
        try container.encode(symptoms, forKey: .symptoms)
        try container.encode(organicControlMethods, forKey: .organicControlMethods)
        try container.encode(chemicalControlMethods, forKey: .chemicalControlMethods)
        try container.encode(preventiveMeasures, forKey: .preventiveMeasures)
    }
}

// MARK: - Pest Severity Enum
enum PestSeverity: String, Codable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Stage Tasks Model
@Model
class StageTasks: Codable {
    var fertilizerInputs: [FertilizerInput]
    var irrigationFrequency: IrrigationFrequency?
    var otherTasks: [String] // e.g., "Weed control", "Pruning"
    
    init(
        fertilizerInputs: [FertilizerInput] = [],
        irrigationFrequency: IrrigationFrequency? = nil,
        otherTasks: [String] = []
    ) {
        self.fertilizerInputs = fertilizerInputs
        self.irrigationFrequency = irrigationFrequency
        self.otherTasks = otherTasks
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case fertilizerInputs, irrigationFrequency, otherTasks
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fertilizerInputs = try container.decode([FertilizerInput].self, forKey: .fertilizerInputs)
        irrigationFrequency = try container.decodeIfPresent(IrrigationFrequency.self, forKey: .irrigationFrequency)
        otherTasks = try container.decode([String].self, forKey: .otherTasks)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fertilizerInputs, forKey: .fertilizerInputs)
        try container.encodeIfPresent(irrigationFrequency, forKey: .irrigationFrequency)
        try container.encode(otherTasks, forKey: .otherTasks)
    }
}

// MARK: - Growth Stage Model
@Model
class CropGrowthStage: Codable {
    var id: UUID
    var name: String
    var durationInDays: Int
    var stageDescription: String?
    var tasks: StageTasks
    var pestVulnerabilities: [PestVulnerability]
    var optimalTemperatureRange: TemperatureRange?
    var criticalWaterRequirement: Bool // Indicates if this stage requires careful water management
    
    init(
        id: UUID = UUID(),
        name: String,
        durationInDays: Int,
        stageDescription: String? = nil,
        tasks: StageTasks = StageTasks(),
        pestVulnerabilities: [PestVulnerability] = [],
        optimalTemperatureRange: TemperatureRange? = nil,
        criticalWaterRequirement: Bool = false
    ) {
        self.id = id
        self.name = name
        self.durationInDays = durationInDays
        self.stageDescription = stageDescription
        self.tasks = tasks
        self.pestVulnerabilities = pestVulnerabilities
        self.optimalTemperatureRange = optimalTemperatureRange
        self.criticalWaterRequirement = criticalWaterRequirement
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, durationInDays, stageDescription, tasks, pestVulnerabilities
        case optimalTemperatureRange, criticalWaterRequirement
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        durationInDays = try container.decode(Int.self, forKey: .durationInDays)
        stageDescription = try container.decodeIfPresent(String.self, forKey: .stageDescription)
        tasks = try container.decode(StageTasks.self, forKey: .tasks)
        pestVulnerabilities = try container.decode([PestVulnerability].self, forKey: .pestVulnerabilities)
        optimalTemperatureRange = try container.decodeIfPresent(TemperatureRange.self, forKey: .optimalTemperatureRange)
        criticalWaterRequirement = try container.decode(Bool.self, forKey: .criticalWaterRequirement)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(durationInDays, forKey: .durationInDays)
        try container.encodeIfPresent(stageDescription, forKey: .stageDescription)
        try container.encode(tasks, forKey: .tasks)
        try container.encode(pestVulnerabilities, forKey: .pestVulnerabilities)
        try container.encodeIfPresent(optimalTemperatureRange, forKey: .optimalTemperatureRange)
        try container.encode(criticalWaterRequirement, forKey: .criticalWaterRequirement)
    }
}

// MARK: - Temperature Range Model
@Model
class TemperatureRange: Codable {
    var minCelsius: Double
    var maxCelsius: Double
    
    init(minCelsius: Double, maxCelsius: Double) {
        self.minCelsius = minCelsius
        self.maxCelsius = maxCelsius
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case minCelsius, maxCelsius
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        minCelsius = try container.decode(Double.self, forKey: .minCelsius)
        maxCelsius = try container.decode(Double.self, forKey: .maxCelsius)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minCelsius, forKey: .minCelsius)
        try container.encode(maxCelsius, forKey: .maxCelsius)
    }
    
    var description: String {
        "\(minCelsius)°C - \(maxCelsius)°C"
    }
}

// MARK: - Crop Profile Model
@Model
class CropProfile: Codable {
    var id: UUID
    var cropName: String
    var scientificName: String?
    var category: CropCategory
    var growthStages: [CropGrowthStage]
    var totalGrowthDuration: Int // Computed from sum of all stage durations
    var imageURL: String?
    var generalNotes: String?
    var soilRequirements: SoilRequirements?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        cropName: String,
        scientificName: String? = nil,
        category: CropCategory,
        growthStages: [CropGrowthStage] = [],
        imageURL: String? = nil,
        generalNotes: String? = nil,
        soilRequirements: SoilRequirements? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.cropName = cropName
        self.scientificName = scientificName
        self.category = category
        self.growthStages = growthStages
        self.totalGrowthDuration = growthStages.reduce(0) { $0 + $1.durationInDays }
        self.imageURL = imageURL
        self.generalNotes = generalNotes
        self.soilRequirements = soilRequirements
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, cropName, scientificName, category, growthStages, totalGrowthDuration
        case imageURL, generalNotes, soilRequirements, createdAt, updatedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        cropName = try container.decode(String.self, forKey: .cropName)
        scientificName = try container.decodeIfPresent(String.self, forKey: .scientificName)
        category = try container.decode(CropCategory.self, forKey: .category)
        growthStages = try container.decode([CropGrowthStage].self, forKey: .growthStages)
        totalGrowthDuration = try container.decode(Int.self, forKey: .totalGrowthDuration)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        generalNotes = try container.decodeIfPresent(String.self, forKey: .generalNotes)
        soilRequirements = try container.decodeIfPresent(SoilRequirements.self, forKey: .soilRequirements)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(cropName, forKey: .cropName)
        try container.encodeIfPresent(scientificName, forKey: .scientificName)
        try container.encode(category, forKey: .category)
        try container.encode(growthStages, forKey: .growthStages)
        try container.encode(totalGrowthDuration, forKey: .totalGrowthDuration)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(generalNotes, forKey: .generalNotes)
        try container.encodeIfPresent(soilRequirements, forKey: .soilRequirements)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    func updateTotalDuration() {
        totalGrowthDuration = growthStages.reduce(0) { $0 + $1.durationInDays }
        updatedAt = Date()
    }
    
    func getStage(byName name: String) -> CropGrowthStage? {
        growthStages.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func getCurrentStage(daysSincePlanting: Int) -> CropGrowthStage? {
        var cumulativeDays = 0
        for stage in growthStages {
            cumulativeDays += stage.durationInDays
            if daysSincePlanting <= cumulativeDays {
                return stage
            }
        }
        return growthStages.last
    }
}

// MARK: - Crop Category Enum
enum CropCategory: String, Codable, CaseIterable {
    case cereal = "Cereal"
    case vegetable = "Vegetable"
    case fruit = "Fruit"
    case legume = "Legume"
    case oilseed = "Oilseed"
    case fiber = "Fiber"
    case spice = "Spice"
    case medicinal = "Medicinal"
    case forage = "Forage"
    case other = "Other"
}

// MARK: - Soil Requirements Model
@Model
class SoilRequirements: Codable {
    var optimalPHRange: PHRange
    var soilType: [String] // e.g., ["Loamy", "Sandy loam"]
    var organicMatterPercentage: Double?
    var drainageRequirement: DrainageType
    
    init(
        optimalPHRange: PHRange,
        soilType: [String],
        organicMatterPercentage: Double? = nil,
        drainageRequirement: DrainageType
    ) {
        self.optimalPHRange = optimalPHRange
        self.soilType = soilType
        self.organicMatterPercentage = organicMatterPercentage
        self.drainageRequirement = drainageRequirement
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case optimalPHRange, soilType, organicMatterPercentage, drainageRequirement
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        optimalPHRange = try container.decode(PHRange.self, forKey: .optimalPHRange)
        soilType = try container.decode([String].self, forKey: .soilType)
        organicMatterPercentage = try container.decodeIfPresent(Double.self, forKey: .organicMatterPercentage)
        drainageRequirement = try container.decode(DrainageType.self, forKey: .drainageRequirement)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(optimalPHRange, forKey: .optimalPHRange)
        try container.encode(soilType, forKey: .soilType)
        try container.encodeIfPresent(organicMatterPercentage, forKey: .organicMatterPercentage)
        try container.encode(drainageRequirement, forKey: .drainageRequirement)
    }
}

// MARK: - pH Range Model
@Model
class PHRange: Codable {
    var min: Double
    var max: Double
    
    init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case min, max
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        min = try container.decode(Double.self, forKey: .min)
        max = try container.decode(Double.self, forKey: .max)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(min, forKey: .min)
        try container.encode(max, forKey: .max)
    }
    
    var description: String {
        "pH \(min) - \(max)"
    }
}

// MARK: - Drainage Type Enum
enum DrainageType: String, Codable {
    case poor = "Poor"
    case moderate = "Moderate"
    case good = "Good"
    case excellent = "Excellent"
}

// MARK: - Example Usage and Sample Data
extension CropProfile {
    static var sampleWheat: CropProfile {
        let germinationStage = CropGrowthStage(
            name: "Germination",
            durationInDays: 7,
            stageDescription: "Seed emergence and initial root development",
            tasks: StageTasks(
                fertilizerInputs: [],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 2,
                    waterAmountPerSession: 20.0,
                    method: "Sprinkler",
                    timeOfDay: "Early Morning"
                ),
                otherTasks: ["Prepare seedbed", "Apply pre-emergence herbicide"]
            ),
            pestVulnerabilities: [
                PestVulnerability(
                    pestName: "Wireworms",
                    scientificName: "Agriotes spp.",
                    severity: .moderate,
                    symptoms: ["Damaged seedlings", "Poor germination"],
                    organicControlMethods: ["Crop rotation", "Use of trap crops"],
                    chemicalControlMethods: ["Seed treatment with insecticides"],
                    preventiveMeasures: ["Deep plowing", "Remove crop residue"]
                )
            ],
            optimalTemperatureRange: TemperatureRange(minCelsius: 15, maxCelsius: 25),
            criticalWaterRequirement: true
        )
        
        let vegetativeStage = CropGrowthStage(
            name: "Vegetative",
            durationInDays: 40,
            stageDescription: "Tillering and leaf development",
            tasks: StageTasks(
                fertilizerInputs: [
                    FertilizerInput(
                        name: "Urea",
                        npkRatio: NPKRatio(nitrogen: 46, phosphorus: 0, potassium: 0),
                        applicationRate: 120.0,
                        applicationMethod: "Broadcast"
                    )
                ],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 7,
                    waterAmountPerSession: 50.0,
                    method: "Flood",
                    timeOfDay: "Early Morning"
                ),
                otherTasks: ["Weed control", "Monitor for diseases"]
            ),
            pestVulnerabilities: [
                PestVulnerability(
                    pestName: "Aphids",
                    scientificName: "Rhopalosiphum padi",
                    severity: .high,
                    symptoms: ["Yellow leaves", "Stunted growth", "Honeydew on leaves"],
                    organicControlMethods: ["Neem oil spray", "Introduce ladybugs"],
                    chemicalControlMethods: ["Systemic insecticides"],
                    preventiveMeasures: ["Remove alternate hosts", "Maintain field hygiene"]
                )
            ],
            optimalTemperatureRange: TemperatureRange(minCelsius: 18, maxCelsius: 24)
        )
        
        let floweringStage = CropGrowthStage(
            name: "Flowering",
            durationInDays: 25,
            stageDescription: "Anthesis and grain formation",
            tasks: StageTasks(
                fertilizerInputs: [
                    FertilizerInput(
                        name: "NPK Complex",
                        npkRatio: NPKRatio(nitrogen: 15, phosphorus: 15, potassium: 15),
                        applicationRate: 80.0,
                        applicationMethod: "Drip"
                    )
                ],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 5,
                    waterAmountPerSession: 40.0,
                    method: "Drip",
                    timeOfDay: "Evening"
                ),
                otherTasks: ["Monitor for rust", "Apply fungicides if needed"]
            ),
            pestVulnerabilities: [
                PestVulnerability(
                    pestName: "Rust (Fungal Disease)",
                    scientificName: "Puccinia spp.",
                    severity: .critical,
                    symptoms: ["Orange-brown pustules on leaves", "Reduced yield"],
                    organicControlMethods: ["Copper-based fungicides", "Remove infected plants"],
                    chemicalControlMethods: ["Triazole fungicides"],
                    preventiveMeasures: ["Use resistant varieties", "Proper spacing"]
                )
            ],
            optimalTemperatureRange: TemperatureRange(minCelsius: 20, maxCelsius: 28),
            criticalWaterRequirement: true
        )
        
        let maturingStage = CropGrowthStage(
            name: "Maturation",
            durationInDays: 28,
            stageDescription: "Grain filling and ripening",
            tasks: StageTasks(
                fertilizerInputs: [],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 10,
                    waterAmountPerSession: 30.0,
                    method: "Flood"
                ),
                otherTasks: ["Reduce irrigation gradually", "Monitor grain moisture"]
            ),
            pestVulnerabilities: [
                PestVulnerability(
                    pestName: "Birds",
                    severity: .moderate,
                    symptoms: ["Grain loss", "Damaged heads"],
                    organicControlMethods: ["Bird netting", "Scarecrows"],
                    chemicalControlMethods: [],
                    preventiveMeasures: ["Early harvesting when possible"]
                )
            ],
            optimalTemperatureRange: TemperatureRange(minCelsius: 22, maxCelsius: 30)
        )
        
        return CropProfile(
            cropName: "Wheat",
            scientificName: "Triticum aestivum",
            category: .cereal,
            growthStages: [germinationStage, vegetativeStage, floweringStage, maturingStage],
            generalNotes: "Cool season crop. Best grown in temperatures between 15-25°C",
            soilRequirements: SoilRequirements(
                optimalPHRange: PHRange(min: 6.0, max: 7.5),
                soilType: ["Loamy", "Clay loam"],
                organicMatterPercentage: 2.5,
                drainageRequirement: .good
            )
        )
    }
    
    static var sampleTomato: CropProfile {
        let germinationStage = CropGrowthStage(
            name: "Germination",
            durationInDays: 5,
            stageDescription: "Seed germination and cotyledon emergence",
            tasks: StageTasks(
                fertilizerInputs: [],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 1,
                    waterAmountPerSession: 5.0,
                    method: "Sprinkler",
                    timeOfDay: "Early Morning"
                ),
                otherTasks: ["Maintain soil moisture", "Protect from extreme heat"]
            ),
            pestVulnerabilities: [],
            optimalTemperatureRange: TemperatureRange(minCelsius: 20, maxCelsius: 30),
            criticalWaterRequirement: true
        )
        
        let vegetativeStage = CropGrowthStage(
            name: "Vegetative",
            durationInDays: 35,
            stageDescription: "Leaf and stem development",
            tasks: StageTasks(
                fertilizerInputs: [
                    FertilizerInput(
                        name: "Nitrogen Fertilizer",
                        npkRatio: NPKRatio(nitrogen: 20, phosphorus: 10, potassium: 10),
                        applicationRate: 60.0,
                        applicationMethod: "Drip"
                    )
                ],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 3,
                    waterAmountPerSession: 15.0,
                    method: "Drip",
                    timeOfDay: "Early Morning"
                ),
                otherTasks: ["Staking", "Pruning suckers"]
            ),
            pestVulnerabilities: [
                PestVulnerability(
                    pestName: "Whiteflies",
                    scientificName: "Bemisia tabaci",
                    severity: .high,
                    symptoms: ["Yellow leaves", "Sticky honeydew", "Sooty mold"],
                    organicControlMethods: ["Yellow sticky traps", "Neem oil"],
                    chemicalControlMethods: ["Imidacloprid"],
                    preventiveMeasures: ["Use insect netting", "Remove infected leaves"]
                )
            ],
            optimalTemperatureRange: TemperatureRange(minCelsius: 21, maxCelsius: 27)
        )
        
        let floweringStage = CropGrowthStage(
            name: "Flowering",
            durationInDays: 20,
            stageDescription: "Flower formation and pollination",
            tasks: StageTasks(
                fertilizerInputs: [
                    FertilizerInput(
                        name: "Phosphorus Fertilizer",
                        npkRatio: NPKRatio(nitrogen: 5, phosphorus: 30, potassium: 15),
                        applicationRate: 50.0,
                        applicationMethod: "Drip"
                    )
                ],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 2,
                    waterAmountPerSession: 20.0,
                    method: "Drip",
                    timeOfDay: "Early Morning"
                ),
                otherTasks: ["Ensure pollination", "Monitor for blossom end rot"]
            ),
            pestVulnerabilities: [
                PestVulnerability(
                    pestName: "Tomato Hornworm",
                    scientificName: "Manduca quinquemaculata",
                    severity: .high,
                    symptoms: ["Defoliation", "Large green caterpillars", "Black droppings"],
                    organicControlMethods: ["Hand picking", "Bacillus thuringiensis (Bt)"],
                    chemicalControlMethods: ["Spinosad"],
                    preventiveMeasures: ["Regular inspection", "Companion planting with basil"]
                )
            ],
            optimalTemperatureRange: TemperatureRange(minCelsius: 18, maxCelsius: 26),
            criticalWaterRequirement: true
        )
        
        let fruitingStage = CropGrowthStage(
            name: "Fruiting",
            durationInDays: 40,
            stageDescription: "Fruit development and ripening",
            tasks: StageTasks(
                fertilizerInputs: [
                    FertilizerInput(
                        name: "Potassium Fertilizer",
                        npkRatio: NPKRatio(nitrogen: 10, phosphorus: 10, potassium: 30),
                        applicationRate: 70.0,
                        applicationMethod: "Drip"
                    )
                ],
                irrigationFrequency: IrrigationFrequency(
                    frequencyInDays: 3,
                    waterAmountPerSession: 25.0,
                    method: "Drip",
                    timeOfDay: "Early Morning"
                ),
                otherTasks: ["Support heavy fruits", "Monitor for diseases"]
            ),
            pestVulnerabilities: [
                PestVulnerability(
                    pestName: "Late Blight",
                    scientificName: "Phytophthora infestans",
                    severity: .critical,
                    symptoms: ["Brown spots on leaves", "White mold on undersides", "Fruit rot"],
                    organicControlMethods: ["Copper fungicide", "Remove infected plants"],
                    chemicalControlMethods: ["Chlorothalonil"],
                    preventiveMeasures: ["Proper spacing", "Avoid overhead watering", "Use resistant varieties"]
                )
            ],
            optimalTemperatureRange: TemperatureRange(minCelsius: 20, maxCelsius: 28)
        )
        
        return CropProfile(
            cropName: "Tomato",
            scientificName: "Solanum lycopersicum",
            category: .vegetable,
            growthStages: [germinationStage, vegetativeStage, floweringStage, fruitingStage],
            generalNotes: "Warm season crop. Requires consistent watering and support structures",
            soilRequirements: SoilRequirements(
                optimalPHRange: PHRange(min: 6.0, max: 6.8),
                soilType: ["Loamy", "Sandy loam"],
                organicMatterPercentage: 3.0,
                drainageRequirement: .excellent
            )
        )
    }
}
