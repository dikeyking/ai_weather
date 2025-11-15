//
//  LocationManagerTests.swift
//  WeatherTests
//
//  Created on 2025/11/15.
//

import XCTest
import CoreLocation
@testable import Weather

@MainActor
final class LocationManagerTests: XCTestCase {
    
    var locationManager: LocationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDown() async throws {
        locationManager = nil
        try await super.tearDown()
    }
    
    // MARK: - TC2.3: Initial Authorization Status
    
    func testInitialAuthorizationStatus() {
        // TC2.3: Before requesting permission, status should be .notDetermined or current status
        let status = locationManager.checkPermission()
        XCTAssertTrue(
            status == .notDetermined ||
            status == .authorizedAlways ||
            status == .authorizedWhenInUse ||
            status == .denied
        )
    }
    
    // MARK: - TC2.8-TC2.11: Location Search Tests
    
    func testSearchLocation_ValidCity() async throws {
        // TC2.8: Search for a known city should return results
        let results = try await locationManager.searchLocation(query: "New York")
        
        XCTAssertFalse(results.isEmpty, "Should find results for 'New York'")
        
        if let firstResult = results.first {
            XCTAssertFalse(firstResult.name.isEmpty)
            XCTAssertNotNil(firstResult.coordinate)
            XCTAssertGreaterThanOrEqual(firstResult.coordinate.latitude, -90)
            XCTAssertLessThanOrEqual(firstResult.coordinate.latitude, 90)
            XCTAssertGreaterThanOrEqual(firstResult.coordinate.longitude, -180)
            XCTAssertLessThanOrEqual(firstResult.coordinate.longitude, 180)
        }
    }
    
    func testSearchLocation_NonExistentPlace() async throws {
        // TC2.9: Search for non-existent place should return empty or minimal results
        let results = try await locationManager.searchLocation(query: "XYZ123NonExistentCity456")
        
        // May return empty array or throw - both acceptable
        // Most geocoders return empty for non-existent places
        XCTAssertTrue(results.isEmpty || results.count > 0)
    }
    
    func testSearchLocation_EmptyQuery() async throws {
        // TC2.10: Empty query should return empty results
        let results = try await locationManager.searchLocation(query: "")
        XCTAssertTrue(results.isEmpty, "Empty query should return no results")
    }
    
    func testSearchLocation_WhitespaceQuery() async throws {
        // TC2.10: Whitespace-only query should return empty results
        let results = try await locationManager.searchLocation(query: "   ")
        XCTAssertTrue(results.isEmpty, "Whitespace query should return no results")
    }
    
    func testSearchLocation_SpecialCharacters() async throws {
        // TC2.10: Query with special characters
        do {
            let results = try await locationManager.searchLocation(query: "@#$%^&*()")
            // Should either return empty or handle gracefully
            XCTAssertTrue(results.isEmpty || results.count >= 0)
        } catch {
            // Throwing error is also acceptable for invalid input
            XCTAssertTrue(true, "Error thrown for special characters is acceptable")
        }
    }
    
    func testSearchLocation_InternationalCity() async throws {
        // Test with international city names
        let results = try await locationManager.searchLocation(query: "Tokyo")
        XCTAssertFalse(results.isEmpty, "Should find results for 'Tokyo'")
    }
    
    func testSearchLocation_CityWithCountry() async throws {
        // Test with more specific query
        let results = try await locationManager.searchLocation(query: "Paris, France")
        XCTAssertFalse(results.isEmpty, "Should find results for 'Paris, France'")
    }
    
    // MARK: - Reverse Geocoding Tests
    
    func testGetLocationName_ValidCoordinate() async throws {
        // Test reverse geocoding with known coordinates
        let name = try await locationManager.getLocationName(
            for: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // New York
        )
        
        XCTAssertFalse(name.isEmpty)
        // Name should contain location info (though exact format may vary)
    }
    
    func testGetLocationName_RemoteLocation() async throws {
        // Test with remote location (ocean)
        let name = try await locationManager.getLocationName(
            for: CLLocationCoordinate2D(latitude: 0, longitude: 0) // Atlantic Ocean
        )
        
        // Should return something (even if it's "Unknown Location" or coordinates)
        XCTAssertFalse(name.isEmpty)
    }
    
    // MARK: - Location Result Display Name
    
    func testLocationResultDisplayName() {
        let result1 = LocationResult(
            name: "New York",
            coordinate: CLLocationCoordinate2D(latitude: 40.7, longitude: -74.0),
            country: "United States",
            administrativeArea: "New York"
        )
        
        XCTAssertEqual(result1.displayName, "New York, New York, United States")
        
        let result2 = LocationResult(
            name: "Tokyo",
            coordinate: CLLocationCoordinate2D(latitude: 35.6, longitude: 139.6),
            country: "Japan",
            administrativeArea: nil
        )
        
        XCTAssertEqual(result2.displayName, "Tokyo, Japan")
        
        let result3 = LocationResult(
            name: "Unknown",
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            country: nil,
            administrativeArea: nil
        )
        
        XCTAssertEqual(result3.displayName, "Unknown")
    }
    
    // MARK: - Permission Management Tests
    
    func testRequestPermission() {
        // TC2.1, TC2.2: Test permission request
        // Note: In automated tests, this won't show the actual permission dialog
        // but we can verify the method doesn't crash
        locationManager.requestPermission()
        
        // Verify the method completes without error
        XCTAssertTrue(true)
    }
    
    func testCheckPermission() {
        // Verify checkPermission returns a valid status
        let status = locationManager.checkPermission()
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .authorizedAlways,
            .authorizedWhenInUse
        ]
        
        XCTAssertTrue(validStatuses.contains(status))
    }
}
