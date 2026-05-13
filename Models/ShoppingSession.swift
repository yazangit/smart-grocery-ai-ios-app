import Foundation

struct ShoppingSession: Identifiable {
    var id: String = UUID().uuidString
    var total: Double
    var date: Date
}
