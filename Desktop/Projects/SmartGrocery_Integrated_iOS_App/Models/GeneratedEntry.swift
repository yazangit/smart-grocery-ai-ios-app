import Foundation

struct GeneratedEntry: Identifiable {
    let id = UUID().uuidString
    let list: GroceryList
    let item: GroceryItem
}
