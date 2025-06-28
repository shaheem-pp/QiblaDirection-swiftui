
import Foundation
import CoreLocation
import Combine

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
