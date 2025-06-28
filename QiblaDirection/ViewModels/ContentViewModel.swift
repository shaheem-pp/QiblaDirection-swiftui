
import Foundation
import Combine
import CoreLocation

class ContentViewModel: ObservableObject {
    @Published var qiblaDirection: Double?
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var deviceHeading: Double = 0.0
    @Published var locationError: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isHeadingAccurate: Bool = false

    private let locationManager = LocationManager()
    private let apiService = QiblaAPIService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        locationManager.$currentLocation
            .assign(to: &$currentLocation)

        locationManager.$deviceHeading
            .assign(to: &$deviceHeading)

        locationManager.$locationError
            .assign(to: &$locationError)

        locationManager.$authorizationStatus
            .assign(to: &$authorizationStatus)

        locationManager.$isHeadingAccurate
            .assign(to: &$isHeadingAccurate)

        apiService.$qiblaDirection
            .assign(to: &$qiblaDirection)

        apiService.$isLoading
            .assign(to: &$isLoading)

        apiService.$error
            .assign(to: &$error)
    }

    func requestLocationAndFetchQibla() {
        locationManager.requestLocation()
        
        locationManager.$currentLocation
            .compactMap { $0 }
            .first()
            .sink { [weak self] location in
                self?.apiService.fetchQiblaDirection(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
            }
            .store(in: &cancellables)
    }
}
