import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var city = ""
    @State private var showingSearch = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Location Status Card
                    LocationStatusCard(locationManager: locationManager)
                    
                    // Current Weather Card
                    if let weatherData = viewModel.weatherData {
                        CurrentWeatherCard(weatherData: weatherData)
                    } else if viewModel.isLoading {
                        LoadingWeatherCard()
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorWeatherCard(message: errorMessage) {
                            // Retry action
                            if let location = locationManager.location {
                                viewModel.fetchWeather(for: location)
                            }
                        }
                    } else {
                        EmptyWeatherCard {
                            // Request location action
                            locationManager.requestLocationPermission()
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch = true }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                SearchWeatherView(viewModel: viewModel)
            }
            .onAppear {
                setupWeatherData()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                if let location = newLocation {
                    viewModel.fetchWeather(for: location)
                }
            }
        }
    }
    
    private func setupWeatherData() {
        // Setup location manager
        viewModel.setup(locationManager: locationManager)
        
        // Request location permission if not determined
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse || 
                  locationManager.authorizationStatus == .authorizedAlways {
            // Start location updates if already authorized
            locationManager.startUpdatingLocation()
        }
        
        // Fetch weather for current location if available
        if let location = locationManager.location {
            viewModel.fetchWeather(for: location)
        }
    }
}

struct LocationStatusCard: View {
    let locationManager: LocationManager
    
    var body: some View {
        HStack {
            Image(systemName: locationIcon)
                .foregroundColor(locationColor)
                .font(.caption)
            
            Text(locationText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if locationManager.authorizationStatus == .notDetermined {
                Button("Enable Location") {
                    locationManager.requestLocationPermission()
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var locationIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.fill"
        case .denied, .restricted:
            return "location.slash"
        default:
            return "location"
        }
    }
    
    private var locationColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        default:
            return .orange
        }
    }
    
    private var locationText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Using Current Location"
        case .denied, .restricted:
            return "Location Access Denied - Please enable in Settings"
        case .notDetermined:
            return "Location Permission Needed"
        @unknown default:
            return "Location Status Unknown"
        }
    }
}

struct CurrentWeatherCard: View {
    let weatherData: WeatherData
    
    var body: some View {
        VStack(spacing: 20) {
            WeatherLocationHeader(locationName: weatherData.name ?? "Unknown Location")
            WeatherMainDisplay(weatherData: weatherData)
            WeatherDetailsRow(weatherData: weatherData)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct WeatherLocationHeader: View {
    let locationName: String
    
    var body: some View {
        Text(locationName)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

struct WeatherMainDisplay: View {
    let weatherData: WeatherData
    
    var body: some View {
        HStack(spacing: 20) {
            WeatherIcon(
                condition: weatherData.weather?.first?.main ?? "",
                size: 60
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(weatherData.main?.temp ?? 0))°")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
                
                Text((weatherData.weather?.first?.description ?? "").capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WeatherDetailsRow: View {
    let weatherData: WeatherData
    
    var body: some View {
        HStack(spacing: 32) {
            WeatherDetail(
                icon: "thermometer",
                title: "Feels like",
                value: "\(Int(weatherData.main?.feelsLike ?? weatherData.main?.temp ?? 0))°"
            )
            
            WeatherDetail(
                icon: "humidity",
                title: "Humidity",
                value: "\(weatherData.main?.humidity ?? 0)%"
            )
            
            if let windSpeed = weatherData.wind?.speed {
                WeatherDetail(
                    icon: "wind",
                    title: "Wind",
                    value: String(format: "%.1f m/s", windSpeed)
                )
            }
        }
    }
}

struct LoadingWeatherCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Getting weather data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct ErrorWeatherCard: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Weather Unavailable")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct EmptyWeatherCard: View {
    let enableLocationAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Weather")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Enable location to see current weather")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Enable Location", action: enableLocationAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct WeatherIcon: View {
    let condition: String
    let size: CGFloat
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size))
            .foregroundStyle(iconGradient)
            .symbolEffect(.bounce, value: condition)
    }
    
    private var iconName: String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }
    
    private var iconGradient: LinearGradient {
        switch condition.lowercased() {
        case "clear":
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "clouds":
            return LinearGradient(colors: [.gray, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "rain", "drizzle":
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "thunderstorm":
            return LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "snow":
            return LinearGradient(colors: [.white, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct WeatherDetail: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct SearchWeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @State private var city = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Location")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Enter city name", text: $city)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                searchWeather()
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                
                Button("Search", action: searchWeather)
                    .buttonStyle(.borderedProminent)
                    .disabled(city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Search Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchWeather() {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty else { return }
        
        viewModel.fetchWeather(for: trimmedCity)
        dismiss()
    }
}

#Preview {
    WeatherView()
}
