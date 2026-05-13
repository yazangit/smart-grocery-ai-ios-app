import SwiftUI

struct GeneratedListView: View {
    @ObservedObject var vm: GroceryViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                List {
                    if vm.generatedItems.isEmpty {
                        Text("No open items found.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.generatedItems) { entry in
                            HStack(spacing: 14) {
                                Text(entry.list.icon)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.item.name)
                                        .font(.headline)
                                    
                                    Text("\(entry.item.quantity) · from \(entry.list.name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("€\(entry.item.price, specifier: "%.2f")")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .hideKeyboardOnTap()
            .navigationTitle("Generated List")
            .toolbar {
                Button("Mark all") {
                    hideKeyboard()
                    vm.markAllGeneratedItemsAsBought()
                }
                .foregroundStyle(.blue)
            }
            .onAppear {
                vm.fetchAllItemsForGeneratedList()
            }
        }
    }
}
