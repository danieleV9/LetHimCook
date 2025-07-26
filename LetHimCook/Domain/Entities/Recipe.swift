import Foundation

struct Recipe: Codable, Sendable, Identifiable {
    let text: String
    
    var id: String { text }
}
