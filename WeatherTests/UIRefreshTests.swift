//
//  UIRefreshTests.swift
//  WeatherTests
//
//  Created on 2025/11/15.
//

import XCTest
import CoreLocation
@testable import Weather

@MainActor
final class UIRefreshTests: XCTestCase {
    
    var viewModel: WeatherViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = WeatherViewModel()
        // Clear UserDefaults to start fresh
        UserDefaults.standard.removeObject(forKey: "savedLocations")
        viewModel = WeatherViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: "savedLocations")
        try await super.tearDown()
    }
    
    // MARK: - TC5.1: Add City and Verify UI Data Update
    
    func testAddCity_WeatherDataUpdatesCorrectly() async throws {
        // Given: A new city location
        let shanghai = LocationInfo(name: "上海", latitude: 31.2304, longitude: 121.4737)
        
        // When: Fetch weather for the city
        await viewModel.fetchWeather(for: shanghai)
        
        // Then: Weather data should be stored with location as key
        let weather = viewModel.getWeather(for: shanghai)
        XCTAssertNotNil(weather, "Weather data should be stored for Shanghai")
        XCTAssertEqual(weather?.location.name, "上海", "Weather location name should match")
        XCTAssertEqual(weather?.location.latitude, 31.2304, accuracy: 0.01, "Latitude should match")
        XCTAssertEqual(weather?.location.longitude, 121.4737, accuracy: 0.01, "Longitude should match")
        
        // Verify temperature is valid
        XCTAssertGreaterThan(weather?.temperature ?? -999, -100, "Temperature should be realistic")
        XCTAssertLessThan(weather?.temperature ?? 999, 100, "Temperature should be realistic")
    }
    
    // MARK: - TC5.2: Multiple Cities Weather Data Isolation
    
    func testMultipleCities_EachHasCorrectWeatherData() async throws {
        // Given: Multiple cities
        let beijing = LocationInfo(name: "北京", latitude: 39.9042, longitude: 116.4074)
        let shanghai = LocationInfo(name: "上海", latitude: 31.2304, longitude: 121.4737)
        let dali = LocationInfo(name: "大理", latitude: 25.6008, longitude: 100.2038)
        
        // When: Fetch weather for all cities
        await viewModel.fetchWeather(for: beijing)
        await viewModel.fetchWeather(for: shanghai)
        await viewModel.fetchWeather(for: dali)
        
        // Then: Each city should have its own weather data
        let beijingWeather = viewModel.getWeather(for: beijing)
        let shanghaiWeather = viewModel.getWeather(for: shanghai)
        let daliWeather = viewModel.getWeather(for: dali)
        
        XCTAssertNotNil(beijingWeather, "Beijing should have weather data")
        XCTAssertNotNil(shanghaiWeather, "Shanghai should have weather data")
        XCTAssertNotNil(daliWeather, "Dali should have weather data")
        
        // Verify each has correct location
        XCTAssertEqual(beijingWeather?.location.name, "北京")
        XCTAssertEqual(shanghaiWeather?.location.name, "上海")
        XCTAssertEqual(daliWeather?.location.name, "大理")
        
        // Verify they are different objects
        XCTAssertNotEqual(beijingWeather?.id, shanghaiWeather?.id, "Each city should have unique weather ID")
        XCTAssertNotEqual(shanghaiWeather?.id, daliWeather?.id, "Each city should have unique weather ID")
    }
    
    // MARK: - TC5.3: Weather Data Updates When Refreshed
    
    func testRefreshWeather_UpdatesExistingData() async throws {
        // Given: A city with initial weather data
        let shanghai = LocationInfo(name: "上海", latitude: 31.2304, longitude: 121.4737)
        await viewModel.fetchWeather(for: shanghai)
        
        let initialWeather = viewModel.getWeather(for: shanghai)
        let initialID = initialWeather?.id
        let initialTime = initialWeather?.time
        
        // Wait a bit to ensure time difference
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // When: Refresh weather
        await viewModel.refreshWeather(for: shanghai)
        
        // Then: Weather data should be updated
        let updatedWeather = viewModel.getWeather(for: shanghai)
        XCTAssertNotNil(updatedWeather, "Updated weather should exist")
        
        // ID should be different (new Weather object)
        XCTAssertNotEqual(initialID, updatedWeather?.id, "Weather ID should change on refresh")
        
        // Time should be newer or same
        if let initialTime = initialTime, let updatedTime = updatedWeather?.time {
            XCTAssertGreaterThanOrEqual(updatedTime, initialTime, "Updated time should be newer or equal")
        }
        
        // Location should remain the same
        XCTAssertEqual(updatedWeather?.location.name, "上海")
    }
    
    // MARK: - TC5.4: Add Location via Search Results
    
    func testAddLocationViaSearch_WeatherDataPopulates() async throws {
        // Given: Search for a city
        viewModel.searchQuery = "Tokyo"
        await viewModel.searchLocation()
        
        guard let tokyoResult = viewModel.searchResults.first else {
            XCTFail("Should find Tokyo in search results")
            return
        }
        
        // When: Add the city
        await viewModel.addLocation(tokyoResult)
        
        // Then: City should be in saved locations
        XCTAssertTrue(viewModel.savedLocations.contains(where: { $0.name == tokyoResult.name }),
                     "Tokyo should be added to saved locations")
        
        // And: Weather data should be available
        let tokyoLocation = viewModel.savedLocations.first { $0.name == tokyoResult.name }
        XCTAssertNotNil(tokyoLocation, "Tokyo location should exist")
        
        if let location = tokyoLocation {
            let weather = viewModel.getWeather(for: location)
            XCTAssertNotNil(weather, "Weather data should be fetched for Tokyo")
            XCTAssertEqual(weather?.location.name, tokyoResult.name, "Weather location should match search result")
        }
    }
    
    // MARK: - TC5.5: Default Cities Load with Weather
    
    func testDefaultCities_LoadWithWeatherData() async throws {
        // Given: Fresh ViewModel (setUp already cleared UserDefaults)
        // Default cities should be loaded
        
        // Then: Should have 3 default cities
        XCTAssertEqual(viewModel.savedLocations.count, 3, "Should have 3 default cities")
        
        // Verify the cities are correct
        let cityNames = viewModel.savedLocations.map { $0.name }
        XCTAssertTrue(cityNames.contains("北京"), "Should contain Beijing")
        XCTAssertTrue(cityNames.contains("上海"), "Should contain Shanghai")
        XCTAssertTrue(cityNames.contains("大理"), "Should contain Dali")
        
        // Wait a bit for async weather fetching to complete
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Verify weather data was fetched for default cities
        for location in viewModel.savedLocations {
            let weather = viewModel.getWeather(for: location)
            XCTAssertNotNil(weather, "Weather should be fetched for \(location.name)")
            
            if let weather = weather {
                XCTAssertEqual(weather.location.name, location.name, "Weather location should match")
                XCTAssertGreaterThan(weather.temperature, -100, "Temperature should be valid")
                XCTAssertLessThan(weather.temperature, 100, "Temperature should be valid")
            }
        }
    }
    
    // MARK: - TC5.6: Remove City Clears Weather Data
    
    func testRemoveCity_ClearsWeatherData() async throws {
        // Given: A city with weather data
        let beijing = LocationInfo(name: "北京", latitude: 39.9042, longitude: 116.4074)
        viewModel.savedLocations.append(beijing)
        await viewModel.fetchWeather(for: beijing)
        
        // Verify weather exists
        XCTAssertNotNil(viewModel.getWeather(for: beijing), "Weather should exist before removal")
        
        // When: Remove the city
        viewModel.removeLocation(beijing)
        
        // Then: Weather data should be cleared
        XCTAssertNil(viewModel.getWeather(for: beijing), "Weather should be removed")
        XCTAssertFalse(viewModel.savedLocations.contains(beijing), "City should be removed from saved locations")
    }
    
    // MARK: - TC5.7: Refresh All Weather Updates All Cities
    
    func testRefreshAllWeather_UpdatesAllCities() async throws {
        // Given: Multiple cities with weather
        let cities = [
            LocationInfo(name: "北京", latitude: 39.9042, longitude: 116.4074),
            LocationInfo(name: "上海", latitude: 31.2304, longitude: 121.4737),
            LocationInfo(name: "大理", latitude: 25.6008, longitude: 100.2038)
        ]
        
        viewModel.savedLocations = cities
        
        // Fetch initial weather
        for city in cities {
            await viewModel.fetchWeather(for: city)
        }
        
        // Store initial IDs
        let initialIDs = cities.compactMap { viewModel.getWeather(for: $0)?.id }
        XCTAssertEqual(initialIDs.count, 3, "All cities should have weather")
        
        // Wait a bit
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Refresh all weather
        await viewModel.refreshAllWeather()
        
        // Then: All cities should have updated weather
        let updatedIDs = cities.compactMap { viewModel.getWeather(for: $0)?.id }
        XCTAssertEqual(updatedIDs.count, 3, "All cities should still have weather")
        
        // IDs should be different (new Weather objects)
        for (initial, updated) in zip(initialIDs, updatedIDs) {
            XCTAssertNotEqual(initial, updated, "Weather IDs should change on refresh")
        }
    }
    
    // MARK: - TC5.8: Selected Location Updates Correctly
    
    func testSelectedLocation_UpdatesWhenFetchingWeather() async throws {
        // Given: A city
        let shanghai = LocationInfo(name: "上海", latitude: 31.2304, longitude: 121.4737)
        
        // When: Fetch weather
        await viewModel.fetchWeather(for: shanghai)
        
        // Then: Selected location should be updated
        XCTAssertEqual(viewModel.selectedLocation, shanghai, "Selected location should be Shanghai")
        XCTAssertEqual(viewModel.selectedLocation?.name, "上海")
    }
}
