
import Foundation

// MARK: - API Service
class QiblaAPIService: ObservableObject {
    @Published var qiblaDirection: Double?
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchQiblaDirection(latitude: Double, longitude: Double) {
        isLoading = true
        error = nil
        
        let urlString = "https://api.aladhan.com/v1/qibla/\(latitude)/\(longitude)"
        print("🌐 Fetching Qibla direction from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("❌ Network error: \(error)")
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        self?.error = "Server error: HTTP \(httpResponse.statusCode)"
                        print("❌ Server error: HTTP \(httpResponse.statusCode)")
                        return
                    }
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    print("❌ No data received")
                    return
                }
                
                // Log raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Raw response: \(jsonString)")
                }
                
                do {
                    let qiblaResponse = try JSONDecoder().decode(QiblaResponse.self, from: data)
                    self?.qiblaDirection = qiblaResponse.data.direction
                    print("✅ Qibla direction: \(qiblaResponse.data.direction)°")
                } catch {
                    self?.error = "Failed to decode response: \(error.localizedDescription)"
                    print("❌ Decoding error: \(error)")
                    
                    // Try to parse error response
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("❌ Error response: \(errorResponse)")
                    }
                }
            }
        }
        
        task.resume()
    }
}
