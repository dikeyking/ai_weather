//
//  Models.swift
//  Weather
//
//  Created on 2025/11/15.
//

import Foundation
import CoreLocation

// MARK: - Weather Data Model
struct Weather: Codable, Identifiable {
    let id: UUID
    let temperature: Double
    let weatherCode: Int
    let windSpeed: Double
    let windDirection: Double
    let time: Date
    let location: LocationInfo
    
    var weatherDescription: String {
        WeatherCode.description(for: weatherCode)
    }
    
    var sfSymbolName: String {
        WeatherCode.sfSymbolName(for: weatherCode)
    }
    
    init(id: UUID = UUID(),
         temperature: Double,
         weatherCode: Int,
         windSpeed: Double,
         windDirection: Double = 0,
         time: Date,
         location: LocationInfo) {
        self.id = id
        self.temperature = temperature
        self.weatherCode = weatherCode
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.time = time
        self.location = location
    }
}

// MARK: - Location Info
struct LocationInfo: Codable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    
    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

// MARK: - Location Search Result
struct LocationResult: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let country: String?
    let administrativeArea: String?
    
    init(id: UUID = UUID(),
         name: String,
         coordinate: CLLocationCoordinate2D,
         country: String? = nil,
         administrativeArea: String? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.country = country
        self.administrativeArea = administrativeArea
    }
    
    var displayName: String {
        var components = [name]
        if let area = administrativeArea {
            components.append(area)
        }
        if let country = country {
            components.append(country)
        }
        return components.joined(separator: ", ")
    }
}

// MARK: - Open-Meteo API Response Models
struct OpenMeteoResponse: Codable {
    let latitude: Double
    let longitude: Double
    let currentWeather: CurrentWeather
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case currentWeather = "current_weather"
    }
}

struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let winddirection: Double
    let weathercode: Int
    let time: String
    
    var date: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: time) ?? Date()
    }
}

// MARK: - Weather Code Mapping
enum WeatherCode {
    /// Maps Open-Meteo weather codes to SF Symbol names
    static func sfSymbolName(for code: Int) -> String {
        switch code {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65:
            return "cloud.rain.fill"
        case 66, 67:
            return "cloud.sleet.fill"
        case 71, 73, 75:
            return "snow"
        case 77:
            return "cloud.snow.fill"
        case 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 85, 86:
            return "cloud.snow.fill"
        case 95:
            return "cloud.bolt.fill"
        case 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
    
    /// Maps Open-Meteo weather codes to human-readable descriptions
    static func description(for code: Int) -> String {
        switch code {
        case 0:
            return "Clear sky"
        case 1:
            return "Mainly clear"
        case 2:
            return "Partly cloudy"
        case 3:
            return "Overcast"
        case 45, 48:
            return "Foggy"
        case 51, 53, 55:
            return "Drizzle"
        case 56, 57:
            return "Freezing drizzle"
        case 61:
            return "Light rain"
        case 63:
            return "Moderate rain"
        case 65:
            return "Heavy rain"
        case 66, 67:
            return "Freezing rain"
        case 71:
            return "Light snow"
        case 73:
            return "Moderate snow"
        case 75:
            return "Heavy snow"
        case 77:
            return "Snow grains"
        case 80, 81, 82:
            return "Rain showers"
        case 85, 86:
            return "Snow showers"
        case 95:
            return "Thunderstorm"
        case 96, 99:
            return "Thunderstorm with hail"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Weather Service Error
enum WeatherError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .decodingError(let error):
            return "Failed to parse weather data: \(error.localizedDescription)"
        case .locationUnavailable:
            return "Location unavailable"
        }
    }
}
