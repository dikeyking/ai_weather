//
//  WeatherViewModel.swift
//  Weather
//
//  Created on 2025/11/15.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var savedLocations: [LocationInfo] = []
    @Published var weatherData: [UUID: Weather] = [:]
    @Published var selectedLocation: LocationInfo?
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchResults: [LocationResult] = []
    @Published var searchQuery = ""
    
    let locationManager = LocationManager()
    let weatherService = WeatherService.shared
    
    init() {
        // Load saved locations from UserDefaults if available
        loadSavedLocations()
    }
    
    // MARK: - Location Management
    
    func requestLocationPermission() {
        locationManager.requestPermission()
    }
    
    func fetchCurrentLocationWeather() async {
        isLoading = true
        error = nil
        
        // Check current authorization status
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // Request permission first
            locationManager.requestPermission()
            // Wait for user response (2 seconds)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Check again after request
            if locationManager.authorizationStatus != .authorizedAlways {
                error = "Location permission denied. Please enable location access in System Settings > Privacy & Security > Location Services."
                isLoading = false
                return
            }
            
        case .restricted, .denied:
            error = "Location permission denied. Please enable location access in System Settings > Privacy & Security > Location Services."
            isLoading = false
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, continue
            break
            
        @unknown default:
            error = "Unknown authorization status"
            isLoading = false
            return
        }
        
        // Request location
        locationManager.requestCurrentLocation()
        
        // Wait for location (with timeout)
        var attempts = 0
        while locationManager.currentLocation == nil && attempts < 30 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            attempts += 1
        }
        
        guard let location = locationManager.currentLocation else {
            error = "Could not get current location. Please check System Settings > Location Services permissions."
            isLoading = false
            return
        }
        
        do {
            let weather = try await weatherService.fetchCurrentWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            // Add to saved locations if not already there
            if !savedLocations.contains(where: { $0.latitude == weather.location.latitude && $0.longitude == weather.location.longitude }) {
                savedLocations.insert(weather.location, at: 0)
                saveSavedLocations()
            }
            
            weatherData[weather.id] = weather
            selectedLocation = weather.location
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Search
    
    func searchLocation() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            searchResults = try await locationManager.searchLocation(query: searchQuery)
        } catch {
            self.error = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }
    }
    
    func addLocation(_ result: LocationResult) async {
        let locationInfo = LocationInfo(
            name: result.name,
            coordinate: result.coordinate
        )
        
        // Check if already exists
        if savedLocations.contains(where: { $0.latitude == locationInfo.latitude && $0.longitude == locationInfo.longitude }) {
            selectedLocation = locationInfo
            return
        }
        
        savedLocations.append(locationInfo)
        saveSavedLocations()
        
        // Fetch weather for this location
        await fetchWeather(for: locationInfo)
        
        // Clear search
        searchQuery = ""
        searchResults = []
    }
    
    // MARK: - Weather Fetching
    
    func fetchWeather(for location: LocationInfo) async {
        isLoading = true
        error = nil
        
        do {
            let weather = try await weatherService.fetchWeather(for: location)
            weatherData[weather.id] = weather
            selectedLocation = location
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func refreshWeather(for location: LocationInfo) async {
        await fetchWeather(for: location)
    }
    
    func refreshAllWeather() async {
        for location in savedLocations {
            do {
                let weather = try await weatherService.fetchWeather(for: location)
                weatherData[weather.id] = weather
            } catch {
                print("Failed to refresh weather for \(location.name): \(error)")
            }
        }
    }
    
    func removeLocation(_ location: LocationInfo) {
        savedLocations.removeAll { $0.latitude == location.latitude && $0.longitude == location.longitude }
        saveSavedLocations()
        
        // Remove from weather data
        weatherData = weatherData.filter { $0.value.location != location }
        
        // Update selection
        if selectedLocation == location {
            selectedLocation = savedLocations.first
        }
    }
    
    // MARK: - Helper: Get Weather for Location
    
    func getWeather(for location: LocationInfo) -> Weather? {
        return weatherData.values.first { $0.location == location }
    }
    
    // MARK: - Persistence
    
    private func saveSavedLocations() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: "savedLocations")
        }
    }
    
    private func loadSavedLocations() {
        if let data = UserDefaults.standard.data(forKey: "savedLocations"),
           let decoded = try? JSONDecoder().decode([LocationInfo].self, from: data) {
            savedLocations = decoded
            selectedLocation = decoded.first
        } else {
            // Initialize with default cities if no saved locations
            let defaultCities = [
                LocationInfo(name: "北京", latitude: 39.9042, longitude: 116.4074),
                LocationInfo(name: "上海", latitude: 31.2304, longitude: 121.4737),
                LocationInfo(name: "大理", latitude: 25.6008, longitude: 100.2038)
            ]
            savedLocations = defaultCities
            selectedLocation = defaultCities.first
            saveSavedLocations()
            
            // Fetch weather for all default cities
            Task {
                for city in defaultCities {
                    await fetchWeather(for: city)
                }
            }
        }
    }
}
