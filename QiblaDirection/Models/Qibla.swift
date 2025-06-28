
import Foundation

// MARK: - Models
struct QiblaResponse: Codable {
    let code: Int
    let status: String
    let data: QiblaData
}

struct QiblaData: Codable {
    let latitude: Double
    let longitude: Double
    let direction: Double
}
