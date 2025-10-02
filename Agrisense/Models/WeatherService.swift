import Foundation
import CoreLocation

class WeatherService {
    private let apiKey = Secrets.openWeatherAPIKey
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let forecastURL = "https://api.openweathermap.org/data/2.5/forecast"

    func fetchWeather(for location: CLLocation, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        // Validate API key
        if apiKey.isEmpty || apiKey == "YOUR_OPENWEATHER_API_KEY_HERE" {
            completion(.failure(NSError(domain: "WeatherService", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenWeather API key is missing. Set OPENWEATHER_API_KEY in environment or update Secrets.swift"])))
            return
        }

        guard let url = URL(string: "\(baseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        performRequest(with: url, completion: completion)
    }
    
    func fetchForecast(for location: CLLocation, completion: @escaping (Result<WeatherForecastData, Error>) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        guard let url = URL(string: "\(forecastURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        performForecastRequest(with: url, completion: completion)
    }

    @available(*, deprecated, message: "Use fetchWeather(for location:) instead")
    func fetchWeather(for city: String, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)&units=metric") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        performRequest(with: url, completion: completion)
    }

    private func performRequest(with url: URL, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }

            // Redact API key from logs
            let redactedURL = url.absoluteString.replacingOccurrences(of: self.apiKey, with: "<REDACTED>")
            let responseText = String(data: data, encoding: .utf8) ?? "<non-text response>"
            let truncatedResponse = responseText.count > 1000 ? String(responseText.prefix(1000)) + "...(truncated)" : responseText
            print("[WeatherService] HTTP \(httpResponse.statusCode) - URL: \(redactedURL)")
            print("[WeatherService] Response body (truncated): \n\(truncatedResponse)")

            // Check for non-200 status codes and try to parse API error
            if !(200...299).contains(httpResponse.statusCode) {
                if let apiError = try? JSONDecoder().decode(WeatherAPIError.self, from: data) {
                    print("[WeatherService] API error: \(apiError.message)")
                    completion(.failure(apiError))
                } else {
                    let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    print("[WeatherService] Non-JSON error message: \(message)")
                    completion(.failure(NSError(domain: "WeatherService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                }
                return
            }

            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                completion(.success(weatherData))
            } catch {
                // If decoding WeatherData fails, try to decode WeatherAPIError for a clearer message
                if let apiError = try? JSONDecoder().decode(WeatherAPIError.self, from: data) {
                    completion(.failure(apiError))
                } else {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    private func performForecastRequest(with url: URL, completion: @escaping (Result<WeatherForecastData, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }

            // Redact API key from logs
            let redactedURL = url.absoluteString.replacingOccurrences(of: self.apiKey, with: "<REDACTED>")
            let responseText = String(data: data, encoding: .utf8) ?? "<non-text response>"
            let truncatedResponse = responseText.count > 1000 ? String(responseText.prefix(1000)) + "...(truncated)" : responseText
            print("[WeatherService] Forecast HTTP \(httpResponse.statusCode) - URL: \(redactedURL)")
            print("[WeatherService] Forecast response body (truncated): \n\(truncatedResponse)")

            if !(200...299).contains(httpResponse.statusCode) {
                if let apiError = try? JSONDecoder().decode(WeatherAPIError.self, from: data) {
                    print("[WeatherService] Forecast API error: \(apiError.message)")
                    completion(.failure(apiError))
                } else {
                    let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    print("[WeatherService] Forecast non-JSON error message: \(message)")
                    completion(.failure(NSError(domain: "WeatherService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                }
                return
            }

            do {
                let forecastData = try JSONDecoder().decode(WeatherForecastData.self, from: data)
                completion(.success(forecastData))
            } catch {
                if let apiError = try? JSONDecoder().decode(WeatherAPIError.self, from: data) {
                    completion(.failure(apiError))
                } else {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Helper method to convert forecast data to daily forecasts
    func processDailyForecast(from forecastData: WeatherForecastData) -> [DailyForecast] {
        let calendar = Calendar.current
        var dailyForecasts: [DailyForecast] = []
        
        // Group forecast items by day
        let groupedByDay = Dictionary(grouping: forecastData.list) { item in
            calendar.startOfDay(for: Date(timeIntervalSince1970: item.dt))
        }
        
        // Get next 3 days starting from tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        
        for i in 0..<3 {
            guard let day = calendar.date(byAdding: .day, value: i, to: startOfTomorrow) else { continue }
            
            if let dayItems = groupedByDay[day], !dayItems.isEmpty {
                let temps = dayItems.map { $0.main.temp }
                let minTemp = temps.min() ?? 0
                let maxTemp = temps.max() ?? 0
                
                // Use weather from noon or closest available
                let noonItem = dayItems.min { item1, item2 in
                    let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
                    let time1 = Date(timeIntervalSince1970: item1.dt)
                    let time2 = Date(timeIntervalSince1970: item2.dt)
                    return abs(time1.timeIntervalSince(noon)) < abs(time2.timeIntervalSince(noon))
                }
                
                if let item = noonItem, let weather = item.weather.first {
                    let forecast = DailyForecast(
                        date: day,
                        minTemp: minTemp,
                        maxTemp: maxTemp,
                        weather: weather,
                        humidity: item.main.humidity ?? 0
                    )
                    dailyForecasts.append(forecast)
                }
            }
        }
        
        return dailyForecasts
    }
}
