import SwiftUI
import CoreLocation

// MARK: - Main View
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient

                VStack {
                    // 1) Top debug header (only in DEBUG builds)
                    #if DEBUG
                    debugInfoSection
                        .padding(.top) // respects the safe‐area
                    #endif

                    Spacer() // pushes compass into vertical center

                    // 2) Compass (or loading / initial / denied states)
                    if let location = viewModel.currentLocation,
                       let qiblaDirection = viewModel.qiblaDirection {
                        ZStack {
                            CompassView(
                                qiblaDirection: qiblaDirection,
                                deviceHeading: viewModel.deviceHeading
                            )
                            .frame(width: 300, height: 300) // fixed size avoids overlap
                            
                            if !viewModel.isHeadingAccurate {
                                CalibrationPromptView()
                            }
                        }
                    } else if viewModel.isLoading {
                        loadingView
                    } else if viewModel.authorizationStatus == .denied {
                        LocationDeniedView()
                    } else {
                        InitialStateView(action: viewModel.requestLocationAndFetchQibla)
                    }

                    Spacer() // pushes info panel down

                    // 3) Bottom info panel
                    if let location = viewModel.currentLocation,
                       let qiblaDirection = viewModel.qiblaDirection {
                        InformationPanelView(
                            qiblaDirection: qiblaDirection,
                            deviceHeading: viewModel.deviceHeading,
                            location: location
                        )
                        .padding(.horizontal)
                        .padding(.bottom)
                    }

                    // 4) Errors at very bottom
                    errorSection
                        .padding(.bottom, 20)
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
    
    // MARK: - Subviews & Helpers
    
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
        DebugInfoView(
            authStatus: viewModel.authorizationStatus.rawValue.description,
            location: viewModel.currentLocation,
            heading: viewModel.deviceHeading,
            isHeadingAccurate: viewModel.isHeadingAccurate
        )
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
