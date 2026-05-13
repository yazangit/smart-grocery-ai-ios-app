import SwiftUI

struct AddListView: View {
    @ObservedObject var vm: GroceryViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var icon = "🛒"
    
    var body: some View {
        NavigationStack {
            Form {
                
                TextField("List name", text: $name)
                
                TextField("Icon", text: $icon)
            }
            .hideKeyboardOnTap()
            .navigationTitle("New List")
            .toolbar {
                
                Button("Save") {
                    
                    hideKeyboard()
                    
                    vm.addList(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        icon: icon.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    
                    dismiss()
                }
                .foregroundStyle(.blue)
                .disabled(
                    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
    }
}
