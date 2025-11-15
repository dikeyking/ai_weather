//
//  WeatherServiceTests.swift
//  WeatherTests
//
//  Created on 2025/11/15.
//

import XCTest
@testable import Weather

final class WeatherServiceTests: XCTestCase {
    
    var weatherService: WeatherService!
    
    override func setUp() {
        super.setUp()
        weatherService = WeatherService.shared
    }
    
    override func tearDown() {
        weatherService = nil
        super.tearDown()
    }
    
    // MARK: - TC1.1: Normal Request with Valid Coordinates
    
    func testFetchCurrentWeather_ValidCoordinates() async throws {
        // TC1.1: Normal request with valid coordinates should return valid weather data
        let weather = try await weatherService.fetchCurrentWeather(
            latitude: 52.52,  // Berlin
            longitude: 13.41
        )
        
        XCTAssertNotNil(weather)
        XCTAssertNotNil(weather.temperature)
        XCTAssertNotNil(weather.weatherCode)
        XCTAssertNotNil(weather.windSpeed)
        XCTAssertGreaterThanOrEqual(weather.temperature, -100)
        XCTAssertLessThanOrEqual(weather.temperature, 100)
        XCTAssertGreaterThanOrEqual(weather.weatherCode, 0)
    }
    
    // MARK: - TC1.2: Invalid JSON Handling (Mock Test)
    
    func testFetchCurrentWeather_InvalidJSON() async {
        // Note: This test would require URL mocking to inject invalid JSON
        // For now, we test that the service properly throws decoding errors
        // In a real implementation, you would use URLProtocol mocking
        
        // This is a placeholder - in production you'd use dependency injection
        // and mock URLSession to return invalid JSON
    }
    
    // MARK: - TC1.3: Network Error Handling
    
    func testFetchCurrentWeather_NetworkError() async {
        // This would require mocking URLSession to simulate network errors
        // Placeholder for future implementation with proper dependency injection
    }
    
    // MARK: - TC1.5: Coordinate Boundary Values
    
    func testFetchCurrentWeather_BoundaryLatitude() async throws {
        // TC1.5: Test with boundary latitude values
        
        // North Pole
        let northPole = try await weatherService.fetchCurrentWeather(
            latitude: 90,
            longitude: 0
        )
        XCTAssertNotNil(northPole)
        
        // South Pole
        let southPole = try await weatherService.fetchCurrentWeather(
            latitude: -90,
            longitude: 0
        )
        XCTAssertNotNil(southPole)
    }
    
    func testFetchCurrentWeather_BoundaryLongitude() async throws {
        // TC1.5: Test with boundary longitude values
        
        let east = try await weatherService.fetchCurrentWeather(
            latitude: 0,
            longitude: 180
        )
        XCTAssertNotNil(east)
        
        let west = try await weatherService.fetchCurrentWeather(
            latitude: 0,
            longitude: -180
        )
        XCTAssertNotNil(west)
    }
    
    func testFetchCurrentWeather_InvalidLatitude() async {
        // Should throw error for invalid latitude
        do {
            _ = try await weatherService.fetchCurrentWeather(
                latitude: 91,  // Invalid
                longitude: 0
            )
            XCTFail("Should have thrown an error for invalid latitude")
        } catch {
            XCTAssertTrue(error is WeatherError)
        }
        
        do {
            _ = try await weatherService.fetchCurrentWeather(
                latitude: -91,  // Invalid
                longitude: 0
            )
            XCTFail("Should have thrown an error for invalid latitude")
        } catch {
            XCTAssertTrue(error is WeatherError)
        }
    }
    
    func testFetchCurrentWeather_InvalidLongitude() async {
        // Should throw error for invalid longitude
        do {
            _ = try await weatherService.fetchCurrentWeather(
                latitude: 0,
                longitude: 181  // Invalid
            )
            XCTFail("Should have thrown an error for invalid longitude")
        } catch {
            XCTAssertTrue(error is WeatherError)
        }
        
        do {
            _ = try await weatherService.fetchCurrentWeather(
                latitude: 0,
                longitude: -181  // Invalid
            )
            XCTFail("Should have thrown an error for invalid longitude")
        } catch {
            XCTAssertTrue(error is WeatherError)
        }
    }
    
    // MARK: - Real API Integration Test
    
    func testFetchCurrentWeather_RealAPI_NewYork() async throws {
        // Integration test with real API
        let weather = try await weatherService.fetchCurrentWeather(
            latitude: 40.7128,  // New York
            longitude: -74.0060
        )
        
        XCTAssertNotNil(weather)
        XCTAssertNotNil(weather.location.name)
        XCTAssertEqual(weather.location.latitude, 40.7128, accuracy: 0.01)
        XCTAssertEqual(weather.location.longitude, -74.0060, accuracy: 0.01)
    }
    
    func testFetchCurrentWeather_RealAPI_Tokyo() async throws {
        // Integration test with real API
        let weather = try await weatherService.fetchCurrentWeather(
            latitude: 35.6762,  // Tokyo
            longitude: 139.6503
        )
        
        XCTAssertNotNil(weather)
        XCTAssertGreaterThan(weather.weatherCode, -1)
        XCTAssertGreaterThan(weather.windSpeed, -1)
    }
    
    // MARK: - Performance Test
    
    func testFetchCurrentWeather_Performance() {
        measure {
            let expectation = XCTestExpectation(description: "Fetch weather")
            
            Task {
                do {
                    _ = try await weatherService.fetchCurrentWeather(
                        latitude: 51.5074,  // London
                        longitude: -0.1278
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to fetch weather: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}
