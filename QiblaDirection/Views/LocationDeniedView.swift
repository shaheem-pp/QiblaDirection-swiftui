
import SwiftUI
import UIKit

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
