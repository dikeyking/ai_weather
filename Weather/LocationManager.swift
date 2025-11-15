//
//  LocationManager.swift
//  Weather
//
//  Created on 2025/11/15.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var error: Error?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission Management
    
    func requestPermission() {
        // Request location permission
        // On macOS, When In Use and Always are functionally equivalent
        // because macOS apps continue to run in the background
        locationManager.requestWhenInUseAuthorization()
    }
    
    func checkPermission() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    // MARK: - Location Updates
    
    func startUpdatingLocation() {
        // macOS: calling startUpdatingLocation() will automatically prompt for permission
        // if status is .notDetermined
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestCurrentLocation() {
        // Request current location
        locationManager.requestLocation()
    }
    
    // MARK: - Location Search (Geocoding)
    
    func searchLocation(query: String) async throws -> [LocationResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(query) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemarks = placemarks else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = placemarks.compactMap { placemark -> LocationResult? in
                    guard let coordinate = placemark.location?.coordinate else {
                        return nil
                    }
                    
                    let name = placemark.locality ?? placemark.name ?? "Unknown"
                    return LocationResult(
                        name: name,
                        coordinate: coordinate,
                        country: placemark.country,
                        administrativeArea: placemark.administrativeArea
                    )
                }
                
                continuation.resume(returning: results)
            }
        }
    }
    
    // MARK: - Reverse Geocoding
    
    func getLocationName(for coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    continuation.resume(returning: "Unknown Location")
                    return
                }
                
                let name = placemark.locality ?? placemark.name ?? "Unknown Location"
                continuation.resume(returning: name)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            currentLocation = location
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
            print("Location error: \(error.localizedDescription)")
        }
    }
}
