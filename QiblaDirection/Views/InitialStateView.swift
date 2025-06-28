
import SwiftUI

// MARK: - Initial State View
struct InitialStateView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Tap to find Qibla direction")
                .font(.title2)
                .foregroundColor(.gray)
            
            Button(action: action) {
                Label("Get Qibla Direction", systemImage: "location.fill")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}
