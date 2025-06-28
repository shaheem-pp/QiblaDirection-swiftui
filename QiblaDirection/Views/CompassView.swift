
import SwiftUI

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
