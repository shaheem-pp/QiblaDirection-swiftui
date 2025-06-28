import SwiftUI
import CoreLocation
import Combine
import UIKit

// MARK: - Models
struct QiblaResponse: Codable {
    let code: Int
    let status: String
    let data: QiblaData
}

struct QiblaData: Codable {
    let latitude: Double
    let longitude: Double
    let direction: Double
}

// MARK: - Location and Heading Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var deviceHeading: Double = 0.0
    @Published var locationError: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isHeadingAccurate: Bool = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = kCLHeadingFilterNone
        
        // Check initial authorization status
        authorizationStatus = locationManager.authorizationStatus
        print("📍 Initial authorization status: \(authorizationStatusString)")
    }
    
    var authorizationStatusString: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
    
    func requestLocation() {
        print("📍 Requesting location...")
        
        // Check authorization status first
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 Authorization not determined, requesting...")
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            locationError = "Location services are restricted on this device."
            print("❌ Location services restricted")
        case .denied:
            locationError = "Location permission denied. Please enable in Settings."
            print("❌ Location permission denied")
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location authorized, starting updates...")
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        @unknown default:
            locationError = "Unknown authorization status"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        print("📍 Authorization status changed to: \(authorizationStatusString)")
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        } else {
            locationManager.stopUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("❌ No location in update")
            return
        }
        
        print("✅ Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location.coordinate
        locationManager.stopUpdatingLocation() // Stop location updates to save power
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy > 0 else {
            isHeadingAccurate = false
            return
        }
        
        // A lower value indicates higher accuracy.
        // We consider <= 15 degrees to be acceptable.
        isHeadingAccurate = newHeading.headingAccuracy <= 15.0
        deviceHeading = newHeading.trueHeading
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Allow the system to display the standard calibration UI when it detects interference.
        return true
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                locationError = "Unable to determine location. Please try again."
            case .denied:
                locationError = "Location permission denied. Please enable in Settings."
            case .network:
                locationError = "Network error. Please check your connection."
            case .headingFailure:
                locationError = "Unable to determine heading. Please try calibrating your device."
            case .regionMonitoringDenied:
                locationError = "Region monitoring denied."
            case .regionMonitoringFailure:
                locationError = "Region monitoring failure."
            case .regionMonitoringSetupDelayed:
                locationError = "Region monitoring setup delayed."
            case .regionMonitoringResponseDelayed:
                locationError = "Region monitoring response delayed."
            case .geocodeFoundNoResult:
                locationError = "No geocoding result found."
            case .geocodeFoundPartialResult:
                locationError = "Partial geocoding result."
            case .geocodeCanceled:
                locationError = "Geocoding canceled."
            default:
                locationError = "Location error: \(error.localizedDescription)"
            }
            
            print("❌ CLError code: \(clError.code.rawValue), description: \(locationError ?? "")")
        } else {
            locationError = error.localizedDescription
        }
    }
}

// MARK: - API Service
class QiblaAPIService: ObservableObject {
    @Published var qiblaDirection: Double?
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchQiblaDirection(latitude: Double, longitude: Double) {
        isLoading = true
        error = nil
        
        let urlString = "https://api.aladhan.com/v1/qibla/\(latitude)/\(longitude)"
        print("🌐 Fetching Qibla direction from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("❌ Network error: \(error)")
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        self?.error = "Server error: HTTP \(httpResponse.statusCode)"
                        print("❌ Server error: HTTP \(httpResponse.statusCode)")
                        return
                    }
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    print("❌ No data received")
                    return
                }
                
                // Log raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Raw response: \(jsonString)")
                }
                
                do {
                    let qiblaResponse = try JSONDecoder().decode(QiblaResponse.self, from: data)
                    self?.qiblaDirection = qiblaResponse.data.direction
                    print("✅ Qibla direction: \(qiblaResponse.data.direction)°")
                } catch {
                    self?.error = "Failed to decode response: \(error.localizedDescription)"
                    print("❌ Decoding error: \(error)")
                    
                    // Try to parse error response
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("❌ Error response: \(errorResponse)")
                    }
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Compass View
struct CompassView: View {
    let qiblaDirection: Double
    let deviceHeading: Double
    @State private var compassSize: CGFloat = 300
    
    var body: some View {
        ZStack {
            // Compass background circle
            Circle()
                .fill(Color.black.opacity(0.1))
                .frame(width: compassSize, height: compassSize)
            
            // Compass markings
            ForEach(0..<360, id: \.self) { degree in
                if degree % 30 == 0 {
                    Rectangle()
                        .fill(degree == 0 ? Color.red : Color.gray)
                        .frame(width: degree % 90 == 0 ? 3 : 2,
                               height: degree % 90 == 0 ? 20 : 15)
                        .offset(y: -compassSize / 2 + 20)
                        .rotationEffect(.degrees(Double(degree)))
                }
            }
            
            // Direction labels
            VStack {
                Text("N")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.red)
                    .offset(y: -compassSize / 2 + 40)
                
                Spacer()
                
                Text("S")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .offset(y: compassSize / 2 - 40)
            }
            .frame(height: compassSize)
            
            HStack {
                Text("W")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .offset(x: -compassSize / 2 + 40)
                
                Spacer()
                
                Text("E")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .offset(x: compassSize / 2 - 40)
            }
            .frame(width: compassSize)
            
            // Qibla indicator arrow
            Image(systemName: "location.north.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.5), radius: 10)
                .rotationEffect(.degrees(qiblaDirection))
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                )
        }
        .rotationEffect(.degrees(-deviceHeading))
        .animation(.easeInOut(duration: 0.3), value: deviceHeading)
    }
}

// MARK: - Error View Component
struct ErrorView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var apiService = QiblaAPIService()
    
    @State private var showLocationAlert = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 20) {
                    debugInfoSection
                    mainContent
                    errorSection
                }
            }
            .navigationTitle("Qibla Compass")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Location Permission Required", isPresented: $showLocationAlert) {
                Button("OK") { }
            } message: {
                Text("Please enable location services to find the Qibla direction.")
            }
        }
        .onAppear {
            print("🚀 App appeared")
            requestLocationAndFetchQibla()
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.2)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var debugInfoSection: some View {
        #if DEBUG
        DebugInfoView(
            authStatus: locationManager.authorizationStatusString,
            location: locationManager.currentLocation,
            heading: locationManager.deviceHeading,
            isHeadingAccurate: locationManager.isHeadingAccurate
        )
        #endif
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let location = locationManager.currentLocation,
           let qiblaDirection = apiService.qiblaDirection {
            compassSection(location: location, qiblaDirection: qiblaDirection)
        } else if apiService.isLoading {
            loadingView
        } else if locationManager.authorizationStatus == .denied {
            LocationDeniedView()
        } else {
            InitialStateView(action: requestLocationAndFetchQibla)
        }
    }
    
    private func compassSection(location: CLLocationCoordinate2D, qiblaDirection: Double) -> some View {
        ZStack {
            VStack {
                CompassView(
                    qiblaDirection: qiblaDirection,
                    deviceHeading: locationManager.deviceHeading
                )
                .padding()
                
                InformationPanelView(
                    qiblaDirection: qiblaDirection,
                    deviceHeading: locationManager.deviceHeading,
                    location: location
                )
            }

            if !locationManager.isHeadingAccurate {
                CalibrationPromptView()
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView("Loading Qibla direction...")
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
    }
    
    @ViewBuilder
    private var errorSection: some View {
        VStack(spacing: 10) {
            if let error = apiService.error {
                ErrorView(message: error, icon: "wifi.exclamationmark")
            }
            
            if let error = locationManager.locationError {
                ErrorView(message: error, icon: "location.slash")
            }
        }
    }
    
    // MARK: - Functions
    
    private func requestLocationAndFetchQibla() {
        print("📱 Requesting location and fetching Qibla...")
        locationManager.requestLocation()
        
        // Observe location changes
        locationManager.$currentLocation
            .compactMap { $0 }
            .first()
            .sink { location in
                print("📍 Location obtained, fetching Qibla direction...")
                apiService.fetchQiblaDirection(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
            }
            .store(in: &cancellables)
    }
}

// MARK: - Debug Info View
struct DebugInfoView: View {
    let authStatus: String
    let location: CLLocationCoordinate2D?
    let heading: Double
    let isHeadingAccurate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("🐛 Debug Info")
                .font(.caption2.bold())
            Text("Auth Status: \(authStatus)")
                .font(.caption2)
            if let location = location {
                Text("Location: \(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                    .font(.caption2)
            }
            Text("Heading: \(heading, specifier: "%.2f")° (Accurate: \(isHeadingAccurate ? "Yes" : "No"))")
                .font(.caption2)
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .foregroundColor(.white)
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Information Panel View
struct InformationPanelView: View {
    let qiblaDirection: Double
    let deviceHeading: Double
    let location: CLLocationCoordinate2D
    
    var body: some View {
        VStack(spacing: 10) {
            qiblaDirectionRow
            currentHeadingRow
            locationRow
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    private var qiblaDirectionRow: some View {
        HStack {
            Label("Qibla Direction", systemImage: "location.north.line")
            Spacer()
            Text("\(Int(qiblaDirection))°")
                .font(.system(.title3, design: .monospaced))
                .bold()
        }
    }
    
    private var currentHeadingRow: some View {
        HStack {
            Label("Current Heading", systemImage: "safari")
            Spacer()
            Text("\(Int(deviceHeading))°")
                .font(.system(.title3, design: .monospaced))
        }
    }
    
    private var locationRow: some View {
        HStack {
            Label("Location", systemImage: "location")
            Spacer()
            Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - Location Denied View
struct LocationDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Location Access Denied")
                .font(.title2)
                .foregroundColor(.red)
            
            Text("Please enable location services in Settings to use the Qibla compass.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Button(action: openSettings) {
                Label("Open Settings", systemImage: "gear")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Initial State View
struct InitialStateView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Tap to find Qibla direction")
                .font(.title2)
                .foregroundColor(.gray)
            
            Button(action: action) {
                Label("Get Qibla Direction", systemImage: "location.fill")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Calibration Prompt View
struct CalibrationPromptView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.2.circlepath.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
            Text("Poor Heading Accuracy")
                .font(.headline)
                .foregroundColor(.white)
            Text("Move to an open area and wave your device in a figure-8 pattern to calibrate the compass.")
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.black.opacity(0.75))
        .cornerRadius(15)
        .padding()
        .transition(.opacity.animation(.easeInOut))
    }
}

#Preview {
    ContentView()
}
