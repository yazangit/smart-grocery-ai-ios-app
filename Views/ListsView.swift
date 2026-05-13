import SwiftUI

struct ListsView: View {
    @ObservedObject var vm: GroceryViewModel
    @State private var showAddList = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                List {
                    Section {
                        HStack(spacing: 12) {
                            Button {
                                hideKeyboard()
                                
                                vm.fetchAllItemsForGeneratedList()
                                vm.generateAIList()
                                
                            } label: {
                                Label("Generate", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    Section {
                        ForEach(vm.lists) { list in
                            ZStack {
                                ListCard(list: list)
                                
                                NavigationLink {
                                    ListDetailView(vm: vm, listId: list.id)
                                } label: {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    hideKeyboard()
                                    vm.deleteList(listId: list.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .hideKeyboardOnTap()
            .navigationTitle("Smart Grocery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        hideKeyboard()
                        showAddList = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddList) {
                AddListView(vm: vm)
                    .presentationDetents([.medium])
            }
            .onAppear {
                vm.fetchLists()
            }
        }
    }
}
