//
//  WeatherModelTests.swift
//  WeatherTests
//
//  Created on 2025/11/15.
//

import XCTest
@testable import Weather

final class WeatherModelTests: XCTestCase {
    
    // MARK: - TC3.1-TC3.6: Weather Code to SF Symbol Mapping
    
    func testWeatherCodeMapping_ClearSky() {
        // TC3.1: code 0 -> sun.max.fill
        let symbol = WeatherCode.sfSymbolName(for: 0)
        XCTAssertEqual(symbol, "sun.max.fill")
    }
    
    func testWeatherCodeMapping_Cloudy() {
        // TC3.2: code 1,2,3 -> cloud variants
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 1), "cloud.sun.fill")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 2), "cloud.sun.fill")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 3), "cloud.fill")
    }
    
    func testWeatherCodeMapping_Rain() {
        // TC3.3: code 61,63,65 -> cloud.rain.fill
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 61), "cloud.rain.fill")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 63), "cloud.rain.fill")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 65), "cloud.rain.fill")
    }
    
    func testWeatherCodeMapping_Snow() {
        // TC3.4: code 71,73,75 -> snow
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 71), "snow")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 73), "snow")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 75), "snow")
    }
    
    func testWeatherCodeMapping_Thunderstorm() {
        // TC3.5: code 95,96,99 -> cloud.bolt variants
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 95), "cloud.bolt.fill")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 96), "cloud.bolt.rain.fill")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 99), "cloud.bolt.rain.fill")
    }
    
    func testWeatherCodeMapping_UnknownCode() {
        // TC3.6: unknown code returns default "cloud.fill"
        XCTAssertEqual(WeatherCode.sfSymbolName(for: 999), "cloud.fill")
        XCTAssertEqual(WeatherCode.sfSymbolName(for: -1), "cloud.fill")
    }
    
    // MARK: - TC3.7-TC3.9: Model Decoding
    
    func testWeatherModelDecoding_ValidJSON() throws {
        // TC3.7: JSON decode test with sample Open-Meteo response
        let json = """
        {
            "latitude": 52.52,
            "longitude": 13.41,
            "current_weather": {
                "temperature": 15.3,
                "windspeed": 12.5,
                "winddirection": 180,
                "weathercode": 3,
                "time": "2025-11-15T14:00"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenMeteoResponse.self, from: data)
        
        XCTAssertEqual(response.latitude, 52.52)
        XCTAssertEqual(response.longitude, 13.41)
        XCTAssertEqual(response.currentWeather.temperature, 15.3)
        XCTAssertEqual(response.currentWeather.weathercode, 3)
        XCTAssertEqual(response.currentWeather.windspeed, 12.5)
        XCTAssertEqual(response.currentWeather.winddirection, 180)
    }
    
    func testWeatherModelDecoding_FieldCompleteness() throws {
        // TC3.8: Field completeness validation
        let json = """
        {
            "latitude": 40.7128,
            "longitude": -74.0060,
            "current_weather": {
                "temperature": 20.0,
                "windspeed": 5.0,
                "winddirection": 90,
                "weathercode": 0,
                "time": "2025-11-15T12:00"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenMeteoResponse.self, from: data)
        
        // Verify all fields are present
        XCTAssertNotNil(response.latitude)
        XCTAssertNotNil(response.longitude)
        XCTAssertNotNil(response.currentWeather.temperature)
        XCTAssertNotNil(response.currentWeather.windspeed)
        XCTAssertNotNil(response.currentWeather.winddirection)
        XCTAssertNotNil(response.currentWeather.weathercode)
        XCTAssertNotNil(response.currentWeather.time)
    }
    
    func testWeatherModelDecoding_DataTypes() throws {
        // TC3.9: Data type validation
        let json = """
        {
            "latitude": 35.6762,
            "longitude": 139.6503,
            "current_weather": {
                "temperature": 18.5,
                "windspeed": 7.2,
                "winddirection": 270,
                "weathercode": 1,
                "time": "2025-11-15T10:00"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenMeteoResponse.self, from: data)
        
        // Verify types
        XCTAssertTrue(type(of: response.latitude) == Double.self)
        XCTAssertTrue(type(of: response.longitude) == Double.self)
        XCTAssertTrue(type(of: response.currentWeather.temperature) == Double.self)
        XCTAssertTrue(type(of: response.currentWeather.windspeed) == Double.self)
        XCTAssertTrue(type(of: response.currentWeather.winddirection) == Double.self)
        XCTAssertTrue(type(of: response.currentWeather.weathercode) == Int.self)
    }
    
    func testWeatherModelDecoding_InvalidJSON() {
        // Should throw when JSON is invalid
        let invalidJSON = """
        {
            "latitude": "not a number",
            "longitude": 13.41
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(OpenMeteoResponse.self, from: data))
    }
    
    // MARK: - Weather Description Tests
    
    func testWeatherDescription() {
        XCTAssertEqual(WeatherCode.description(for: 0), "Clear sky")
        XCTAssertEqual(WeatherCode.description(for: 61), "Light rain")
        XCTAssertEqual(WeatherCode.description(for: 95), "Thunderstorm")
        XCTAssertEqual(WeatherCode.description(for: 999), "Unknown")
    }
    
    // MARK: - LocationInfo Tests
    
    func testLocationInfoCodable() throws {
        let location = LocationInfo(name: "Test City", latitude: 40.7128, longitude: -74.0060)
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(location)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LocationInfo.self, from: data)
        
        XCTAssertEqual(decoded.name, location.name)
        XCTAssertEqual(decoded.latitude, location.latitude)
        XCTAssertEqual(decoded.longitude, location.longitude)
    }
}
