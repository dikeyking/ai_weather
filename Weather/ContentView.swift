//
//  ContentView.swift
//  Weather
//
//  Created by Dikey King on 2025/11/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        NavigationSplitView {
            // Left Sidebar: City List
            CityListView(viewModel: viewModel)
        } detail: {
            // Right Detail: Weather Details
            WeatherDetailView(viewModel: viewModel)
        }
        .task {
            // Fetch current location weather on startup
            await viewModel.fetchCurrentLocationWeather()
        }
    }
}

// MARK: - City List View (Left Sidebar)

struct CityListView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search location...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await viewModel.searchLocation()
                        }
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                        viewModel.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)
            .padding()
            
            Divider()
            
            // Search Results or Saved Locations
            if !viewModel.searchResults.isEmpty {
                List(viewModel.searchResults) { result in
                    Button {
                        Task {
                            await viewModel.addLocation(result)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.name)
                                .font(.headline)
                            if let area = result.administrativeArea, let country = result.country {
                                Text("\(area), \(country)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                List(viewModel.savedLocations, id: \.self, selection: $viewModel.selectedLocation) { location in
                    CityRowView(location: location, viewModel: viewModel)
                        .tag(location)
                }
            }
            
            Spacer()
            
            // Current Location Button
            Divider()
            Button {
                Task {
                    await viewModel.fetchCurrentLocationWeather()
                }
            } label: {
                Label("Current Location", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .navigationTitle("Locations")
    }
}

// MARK: - City Row View

struct CityRowView: View {
    let location: LocationInfo
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                
                if let weather = viewModel.getWeather(for: location) {
                    Text("\(Int(weather.temperature))°C")
                        .font(.title2)
                        .bold()
                }
            }
            
            Spacer()
            
            if let weather = viewModel.getWeather(for: location) {
                Image(systemName: weather.sfSymbolName)
                    .font(.title)
                    .symbolRenderingMode(.multicolor)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedLocation = location
            if viewModel.getWeather(for: location) == nil {
                Task {
                    await viewModel.fetchWeather(for: location)
                }
            }
        }
        .contextMenu {
            Button("Refresh") {
                Task {
                    await viewModel.refreshWeather(for: location)
                }
            }
            Button("Remove", role: .destructive) {
                viewModel.removeLocation(location)
            }
        }
    }
}

// MARK: - Weather Detail View (Right Detail)

struct WeatherDetailView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading weather...")
                        .foregroundColor(.secondary)
                }
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Request Permission") {
                        viewModel.requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let selectedLocation = viewModel.selectedLocation,
                      let weather = viewModel.getWeather(for: selectedLocation) {
                WeatherContentView(weather: weather, viewModel: viewModel)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 80))
                        .symbolRenderingMode(.multicolor)
                    Text("Select a location")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Choose a city from the list or search for a new location")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Weather Content View

struct WeatherContentView: View {
    let weather: Weather
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Location and Time
                VStack(spacing: 8) {
                    Text(weather.location.name)
                        .font(.largeTitle)
                        .bold()
                    Text("Updated: \(weather.time.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Weather Icon and Temperature
                VStack(spacing: 16) {
                    Image(systemName: weather.sfSymbolName)
                        .font(.system(size: 100))
                        .symbolRenderingMode(.multicolor)
                    
                    Text("\(Int(weather.temperature))°C")
                        .font(.system(size: 80, weight: .thin))
                    
                    Text(weather.weatherDescription)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .padding(.horizontal, 40)
                
                // Additional Details
                HStack(spacing: 40) {
                    WeatherDetailItem(
                        icon: "wind",
                        title: "Wind Speed",
                        value: "\(Int(weather.windSpeed)) km/h"
                    )
                    
                    WeatherDetailItem(
                        icon: "safari",
                        title: "Wind Direction",
                        value: "\(Int(weather.windDirection))°"
                    )
                }
                
                // Refresh Button
                Button {
                    Task {
                        await viewModel.refreshWeather(for: weather.location)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
            .padding(40)
        }
    }
}

// MARK: - Weather Detail Item

struct WeatherDetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
    }
}

#Preview {
    ContentView()
}
