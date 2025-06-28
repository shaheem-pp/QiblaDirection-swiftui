
import SwiftUI
import CoreLocation

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
