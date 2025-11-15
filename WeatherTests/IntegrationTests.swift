//
//  IntegrationTests.swift
//  WeatherTests
//
//  Created on 2025/11/15.
//

import XCTest
import CoreLocation
@testable import Weather

@MainActor
final class IntegrationTests: XCTestCase {
    
    var viewModel: WeatherViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = WeatherViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - TC4.1: Complete Flow - Permission → Location → Weather → UI
    
    func testCompleteFlow_SearchCityToWeather() async throws {
        // TC4.2: Search city → Get coordinates → Request weather → Add to list
        
        // Set search query
        viewModel.searchQuery = "London"
        
        // Perform search
        await viewModel.searchLocation()
        
        // Verify search results
        XCTAssertFalse(viewModel.searchResults.isEmpty, "Should find results for London")
        
        guard let firstResult = viewModel.searchResults.first else {
            XCTFail("No search results found")
            return
        }
        
        // Add location
        await viewModel.addLocation(firstResult)
        
        // Verify location was added
        XCTAssertTrue(
            viewModel.savedLocations.contains(where: { $0.name == firstResult.name }),
            "Location should be added to saved locations"
        )
        
        // Verify weather was fetched
        let locationInfo = viewModel.savedLocations.first { $0.name == firstResult.name }
        XCTAssertNotNil(locationInfo, "Location info should exist")
        
        if let location = locationInfo {
            let weather = viewModel.getWeather(for: location)
            XCTAssertNotNil(weather, "Weather should be fetched for the location")
            
            if let weather = weather {
                // Verify weather data integrity
                XCTAssertNotNil(weather.temperature)
                XCTAssertNotNil(weather.weatherCode)
                XCTAssertNotNil(weather.windSpeed)
                XCTAssertFalse(weather.sfSymbolName.isEmpty)
                XCTAssertFalse(weather.weatherDescription.isEmpty)
            }
        }
        
        // Verify search was cleared
        XCTAssertTrue(viewModel.searchQuery.isEmpty, "Search query should be cleared")
        XCTAssertTrue(viewModel.searchResults.isEmpty, "Search results should be cleared")
    }
    
    // MARK: - TC4.2: Search and Add Multiple Cities
    
    func testAddMultipleCities() async throws {
        let cities = ["Paris", "Tokyo", "Sydney"]
        
        for city in cities {
            viewModel.searchQuery = city
            await viewModel.searchLocation()
            
            if let result = viewModel.searchResults.first {
                await viewModel.addLocation(result)
            }
            
            // Small delay between requests to avoid rate limiting
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // Verify multiple locations were added
        XCTAssertGreaterThanOrEqual(viewModel.savedLocations.count, cities.count)
    }
    
    // MARK: - Weather Refresh Tests
    
    func testRefreshWeather() async throws {
        // Add a location
        viewModel.searchQuery = "Berlin"
        await viewModel.searchLocation()
        
        guard let firstResult = viewModel.searchResults.first else {
            XCTFail("No search results")
            return
        }
        
        await viewModel.addLocation(firstResult)
        
        guard let location = viewModel.savedLocations.first else {
            XCTFail("No saved locations")
            return
        }
        
        // Get initial weather
        let initialWeather = viewModel.getWeather(for: location)
        XCTAssertNotNil(initialWeather)
        
        // Refresh weather
        await viewModel.refreshWeather(for: location)
        
        // Verify weather was refreshed
        let refreshedWeather = viewModel.getWeather(for: location)
        XCTAssertNotNil(refreshedWeather)
    }
    
    // MARK: - Remove Location Test
    
    func testRemoveLocation() async throws {
        // Add a location
        viewModel.searchQuery = "Madrid"
        await viewModel.searchLocation()
        
        guard let firstResult = viewModel.searchResults.first else {
            XCTFail("No search results")
            return
        }
        
        await viewModel.addLocation(firstResult)
        
        let initialCount = viewModel.savedLocations.count
        XCTAssertGreaterThan(initialCount, 0)
        
        // Remove the location
        if let location = viewModel.savedLocations.first {
            viewModel.removeLocation(location)
            
            // Verify location was removed
            XCTAssertEqual(viewModel.savedLocations.count, initialCount - 1)
            
            // Verify weather data was also removed
            let weather = viewModel.getWeather(for: location)
            XCTAssertNil(weather, "Weather data should be removed")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testSearchLocation_EmptyQuery() async {
        // TC2.10: Empty query handling
        viewModel.searchQuery = ""
        await viewModel.searchLocation()
        
        XCTAssertTrue(viewModel.searchResults.isEmpty, "Empty query should return no results")
    }
    
    func testSearchLocation_WhitespaceQuery() async {
        viewModel.searchQuery = "   "
        await viewModel.searchLocation()
        
        XCTAssertTrue(viewModel.searchResults.isEmpty, "Whitespace query should return no results")
    }
    
    // MARK: - Persistence Tests
    
    func testLocationPersistence() async throws {
        // Add locations
        let testCities = ["Rome", "Amsterdam"]
        
        for city in testCities {
            viewModel.searchQuery = city
            await viewModel.searchLocation()
            
            if let result = viewModel.searchResults.first {
                await viewModel.addLocation(result)
            }
            
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        
        let savedCount = viewModel.savedLocations.count
        XCTAssertGreaterThan(savedCount, 0)
        
        // Create new view model (simulating app restart)
        let newViewModel = WeatherViewModel()
        
        // Verify locations were persisted
        XCTAssertEqual(newViewModel.savedLocations.count, savedCount)
    }
    
    // MARK: - Duplicate Location Test
    
    func testAddDuplicateLocation() async throws {
        // Add a location
        viewModel.searchQuery = "Barcelona"
        await viewModel.searchLocation()
        
        guard let firstResult = viewModel.searchResults.first else {
            XCTFail("No search results")
            return
        }
        
        await viewModel.addLocation(firstResult)
        let initialCount = viewModel.savedLocations.count
        
        // Try to add the same location again
        viewModel.searchQuery = "Barcelona"
        await viewModel.searchLocation()
        
        if let duplicateResult = viewModel.searchResults.first {
            await viewModel.addLocation(duplicateResult)
        }
        
        // Verify duplicate was not added
        XCTAssertEqual(viewModel.savedLocations.count, initialCount,
                      "Duplicate location should not be added")
    }
    
    // MARK: - Weather Code to Symbol Integration
    
    func testWeatherSymbolIntegration() async throws {
        // Fetch real weather and verify symbol mapping
        viewModel.searchQuery = "Oslo"
        await viewModel.searchLocation()
        
        guard let firstResult = viewModel.searchResults.first else {
            XCTFail("No search results")
            return
        }
        
        await viewModel.addLocation(firstResult)
        
        guard let location = viewModel.savedLocations.first,
              let weather = viewModel.getWeather(for: location) else {
            XCTFail("Weather not found")
            return
        }
        
        // Verify symbol name is valid
        XCTAssertFalse(weather.sfSymbolName.isEmpty)
        
        // Verify it's a valid weather-related SF Symbol
        let validSymbols = [
            "sun.max.fill", "cloud.sun.fill", "cloud.fill", "cloud.fog.fill",
            "cloud.drizzle.fill", "cloud.rain.fill", "cloud.sleet.fill", "snow",
            "cloud.snow.fill", "cloud.heavyrain.fill", "cloud.bolt.fill", "cloud.bolt.rain.fill"
        ]
        
        XCTAssertTrue(validSymbols.contains(weather.sfSymbolName) || weather.sfSymbolName == "cloud.fill",
                     "Symbol should be a valid weather symbol")
    }
}
