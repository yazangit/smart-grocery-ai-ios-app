import Foundation

struct GroceryList: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var icon: String
    var items: [GroceryItem] = []
}
