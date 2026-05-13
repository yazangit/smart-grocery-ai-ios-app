import SwiftUI

struct AddItemView: View {
    @ObservedObject var vm: GroceryViewModel
    @Environment(\.dismiss) var dismiss
    
    let listId: String
    
    @State private var name = ""
    @State private var quantity = ""
    @State private var price = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $name)
                TextField("Quantity", text: $quantity)
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
            }
            .hideKeyboardOnTap()
            .navigationTitle("New Item")
            .toolbar {
                Button("Save") {
                    hideKeyboard()
                    
                    let cleanPrice = price.replacingOccurrences(of: ",", with: ".")
                    let priceValue = Double(cleanPrice) ?? 0.0
                    
                    vm.addItem(
                        to: listId,
                        name: name,
                        quantity: quantity,
                        price: priceValue
                    )
                    
                    dismiss()
                }
                .foregroundStyle(.blue)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
