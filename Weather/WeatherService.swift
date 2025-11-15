//
//  WeatherService.swift
//  Weather
//
//  Created on 2025/11/15.
//

import Foundation
import CoreLocation

class WeatherService {
    static let shared = WeatherService()
    
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        // Create a custom URLSession configuration that bypasses proxy
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [:]  // Disable proxy
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Fetch Current Weather
    
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather {
        // Validate coordinates
        guard latitude >= -90 && latitude <= 90 else {
            throw WeatherError.invalidURL
        }
        guard longitude >= -180 && longitude <= 180 else {
            throw WeatherError.invalidURL
        }
        
        // Build URL
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current_weather", value: "true"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        // Make request
        let (data, response) = try await session.data(from: url)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.invalidResponse
        }
        
        // Decode response
        let decoder = JSONDecoder()
        let apiResponse: OpenMeteoResponse
        
        do {
            apiResponse = try decoder.decode(OpenMeteoResponse.self, from: data)
        } catch {
            throw WeatherError.decodingError(error)
        }
        
        // Get location name
        let locationName = try await getLocationName(latitude: latitude, longitude: longitude)
        
        // Convert to Weather model
        let weather = Weather(
            temperature: apiResponse.currentWeather.temperature,
            weatherCode: apiResponse.currentWeather.weathercode,
            windSpeed: apiResponse.currentWeather.windspeed,
            windDirection: apiResponse.currentWeather.winddirection,
            time: apiResponse.currentWeather.date,
            location: LocationInfo(
                name: locationName,
                latitude: apiResponse.latitude,
                longitude: apiResponse.longitude
            )
        )
        
        return weather
    }
    
    // MARK: - Fetch Weather for Location Info
    
    func fetchWeather(for location: LocationInfo) async throws -> Weather {
        return try await fetchCurrentWeather(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }
    
    // MARK: - Helper: Get Location Name
    
    private func getLocationName(latitude: Double, longitude: Double) async throws -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    // Fallback to coordinates if geocoding fails
                    continuation.resume(returning: "\(latitude), \(longitude)")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    continuation.resume(returning: "\(latitude), \(longitude)")
                    return
                }
                
                let name = placemark.locality ?? placemark.name ?? "\(latitude), \(longitude)"
                continuation.resume(returning: name)
            }
        }
    }
}
