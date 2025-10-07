import Foundation
import CoreLocation

/// LocationManager with robust error handling and configurable update modes
/// - Supports both single-shot and continuous location updates
/// - Thread-safe with proper concurrency handling
/// - Publishes errors for UI consumption
@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let delegateQueue = DispatchQueue(label: "com.agrisense.location", qos: .userInitiated)
    
    @Published var location: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var error: LocationError?
    @Published var isUpdating = false
    
    /// When true, location updates stop after first successful location
    var singleShotMode = true
    
    override init() {
        // Initialize authorization status safely
        let manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters in continuous mode
    }
    
    // MARK: - Public API
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation(singleShot: Bool = true) {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            error = .permissionDenied
            return
        }
        
        singleShotMode = singleShot
        isUpdating = true
        error = nil
        
        if singleShot {
            locationManager.requestLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdatingLocation() {
        guard isUpdating else { return }
        locationManager.stopUpdatingLocation()
        isUpdating = false
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.error = nil
                // Auto-start location updates when permission granted
                if !self.isUpdating {
                    self.startUpdatingLocation()
                }
            case .denied, .restricted:
                self.error = .permissionDenied
                self.stopUpdatingLocation()
            case .notDetermined:
                break
            @unknown default:
                self.error = .unknown
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.first else { return }
            
            self.location = location
            self.error = nil
            
            // Stop updates in single-shot mode
            if self.singleShotMode {
                self.stopUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("[LocationManager] Failed to get location: \(error.localizedDescription)")
            
            let clError = error as? CLError
            if clError?.code == .denied {
                self.error = .permissionDenied
            } else if clError?.code == .network {
                self.error = .networkError
            } else {
                self.error = .locationUnavailable(error.localizedDescription)
            }
            
            self.stopUpdatingLocation()
        }
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable(String)
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable in Settings."
        case .locationUnavailable(let message):
            return "Location unavailable: \(message)"
        case .networkError:
            return "Network error while getting location."
        case .unknown:
            return "Unknown location error occurred."
        }
    }
}
