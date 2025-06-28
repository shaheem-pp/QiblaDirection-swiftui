import SwiftUI
import CoreLocation

// MARK: - Main View
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
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
        }
        .onAppear {
            print("🚀 App appeared")
            viewModel.requestLocationAndFetchQibla()
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
            authStatus: viewModel.authorizationStatus.rawValue.description,
            location: viewModel.currentLocation,
            heading: viewModel.deviceHeading,
            isHeadingAccurate: viewModel.isHeadingAccurate
        )
        #endif
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let location = viewModel.currentLocation,
           let qiblaDirection = viewModel.qiblaDirection {
            compassSection(location: location, qiblaDirection: qiblaDirection)
        } else if viewModel.isLoading {
            loadingView
        } else if viewModel.authorizationStatus == .denied {
            LocationDeniedView()
        } else {
            InitialStateView(action: viewModel.requestLocationAndFetchQibla)
        }
    }
    
    private func compassSection(location: CLLocationCoordinate2D, qiblaDirection: Double) -> some View {
        ZStack {
            VStack {
                CompassView(
                    qiblaDirection: qiblaDirection,
                    deviceHeading: viewModel.deviceHeading
                )
                .padding()
                
                InformationPanelView(
                    qiblaDirection: qiblaDirection,
                    deviceHeading: viewModel.deviceHeading,
                    location: location
                )
            }

            if !viewModel.isHeadingAccurate {
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
            if let error = viewModel.error {
                ErrorView(message: error, icon: "wifi.exclamationmark")
            }
            
            if let error = viewModel.locationError {
                ErrorView(message: error, icon: "location.slash")
            }
        }
    }
}

#Preview {
    ContentView()
}