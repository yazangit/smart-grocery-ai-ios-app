import SwiftUI

struct ListDetailView: View {
    @ObservedObject var vm: GroceryViewModel
    let listId: String
    
    @State private var showAddItem = false
    
    var list: GroceryList? {
        vm.lists.first { $0.id == listId }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            List {
                if let list {
                    ForEach(list.items) { item in
                        HStack(spacing: 14) {
                            Button {
                                hideKeyboard()
                                vm.toggleBought(listId: listId, itemId: item.id)
                            } label: {
                                Image(systemName: item.bought ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(item.bought ? .blue : .secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .strikethrough(item.bought)
                                
                                Text(item.quantity)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("€\(item.price, specifier: "%.2f")")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete { indexSet in
                        hideKeyboard()
                        
                        for index in indexSet {
                            let item = list.items[index]
                            vm.deleteItem(listId: list.id, itemId: item.id)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .hideKeyboardOnTap()
        .navigationTitle(list?.name ?? "List")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    hideKeyboard()
                    showAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView(vm: vm, listId: listId)
                .presentationDetents([.medium])
        }
        .onAppear {
            vm.fetchItems(for: listId)
        }
    }
}
