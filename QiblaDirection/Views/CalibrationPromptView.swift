
import SwiftUI

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
