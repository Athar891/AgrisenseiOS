import Foundation
import CoreLocation
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherData: WeatherData? = nil
    @Published var dailyForecasts: [DailyForecast] = []
    @Published var isLoading = false
    @Published var isLoadingForecast = false
    @Published var errorMessage: String? = nil

    private let weatherService = WeatherService()
    private var locationManager: LocationManager?
    private var cancellables = Set<AnyCancellable>()

    func setup(locationManager: LocationManager) {
        self.locationManager = locationManager
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.fetchWeatherAndForecast(for: location)
            }
            .store(in: &cancellables)
    }
    
    func fetchWeatherAndForecast(for location: CLLocation) {
        fetchWeather(for: location)
        fetchForecast(for: location)
    }

    func fetchWeather(for location: CLLocation) {
        isLoading = true
        errorMessage = nil

        weatherService.fetchWeather(for: location) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let weatherData):
                    self?.weatherData = weatherData
                case .failure(let error):
                    if let apiError = error as? WeatherAPIError {
                        self?.errorMessage = apiError.message.capitalized
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func fetchForecast(for location: CLLocation) {
        isLoadingForecast = true

        weatherService.fetchForecast(for: location) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingForecast = false
                switch result {
                case .success(let forecastData):
                    self?.dailyForecasts = self?.weatherService.processDailyForecast(from: forecastData) ?? []
                case .failure(let error):
                    // Don't override main error message, forecast is secondary
                    print("Forecast fetch error: \(error.localizedDescription)")
                }
            }
        }
    }

    @available(*, deprecated, message: "Use fetchWeather(for location:) instead")
    func fetchWeather(for city: String) {
        isLoading = true
        errorMessage = nil

        weatherService.fetchWeather(for: city) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let weatherData):
                    self?.weatherData = weatherData
                case .failure(let error):
                    if let apiError = error as? WeatherAPIError {
                        self?.errorMessage = apiError.message.capitalized
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}
