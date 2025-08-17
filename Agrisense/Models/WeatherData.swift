import Foundation

// MARK: - WeatherData
struct WeatherData: Codable {
    let weather: [Weather]?
    let main: Main?
    let name: String?
    let wind: Wind?
    let visibility: Int?
    let dt: TimeInterval?
}

// MARK: - Main
struct Main: Codable {
    let temp: Double
    let feelsLike: Double?
    let tempMin: Double?
    let tempMax: Double?
    let humidity: Int?
    let pressure: Int?
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case humidity, pressure
    }
}

// MARK: - Weather
struct Weather: Codable {
    let main: String
    let description: String
    let icon: String
}

// MARK: - Wind
struct Wind: Codable {
    let speed: Double?
    let deg: Int?
}

// MARK: - WeatherForecastData
struct WeatherForecastData: Codable {
    let list: [ForecastItem]
    let city: City
}

// MARK: - ForecastItem
struct ForecastItem: Codable, Identifiable {
    let dt: TimeInterval
    let main: Main
    let weather: [Weather]
    let wind: Wind?
    let visibility: Int?
    let dtTxt: String
    
    var id: TimeInterval { dt }
    
    enum CodingKeys: String, CodingKey {
        case dt, main, weather, wind, visibility
        case dtTxt = "dt_txt"
    }
}

// MARK: - City
struct City: Codable {
    let name: String
    let country: String
}

// MARK: - DailyForecast
struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let minTemp: Double
    let maxTemp: Double
    let weather: Weather
    let humidity: Int
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - WeatherAPIError
struct WeatherAPIError: Codable, Error {
    let cod: String
    let message: String
}
