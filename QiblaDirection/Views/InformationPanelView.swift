
import SwiftUI
import CoreLocation

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
