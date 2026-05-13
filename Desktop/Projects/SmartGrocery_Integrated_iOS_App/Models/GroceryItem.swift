import Foundation

struct GroceryItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var quantity: String
    var price: Double
    var bought: Bool = false
}
