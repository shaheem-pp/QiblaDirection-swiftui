import SwiftUI

// MARK: - Compass View
struct CompassView: View {
    let qiblaDirection: Double
    let deviceHeading: Double

    var body: some View {
        GeometryReader { proxy in
            // Diameter = 90% of the smaller side
            let diameter = min(proxy.size.width, proxy.size.height) * 0.9

            ZStack {
                // 1) Background circle
                Circle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: diameter, height: diameter)

                // 2) Tick marks every 30°
                ForEach(Array(stride(from: 0, to: 360, by: 30)), id: \.self) { deg in
                    Rectangle()
                        .fill(deg == 0 ? Color.red : Color.gray)
                        .frame(
                            width: deg % 90 == 0 ? 3 : 2,
                            height: deg % 90 == 0 ? 20 : 15
                        )
                        .offset(y: -diameter / 2 + 20)
                        .rotationEffect(.degrees(Double(deg)))
                }

                // 3) Cardinal labels
                Text("N")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.red)
                    .offset(y: -diameter / 2 + 40)

                Text("S")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .offset(y: diameter / 2 - 40)

                Text("W")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .offset(x: -diameter / 2 + 40)

                Text("E")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .offset(x: diameter / 2 - 40)

                // 4) Qibla arrow
                Image(systemName: "location.north.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 10)
                    .rotationEffect(.degrees(qiblaDirection))

                // 5) Center dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
            }
            // Rotate the whole dial by the device heading
            .rotationEffect(.degrees(-deviceHeading))
            .animation(.easeInOut(duration: 0.3), value: deviceHeading)
            // Fix its own size…
            .frame(width: diameter, height: diameter)
            // …then let it center in the available space
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
