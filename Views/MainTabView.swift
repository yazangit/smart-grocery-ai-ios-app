import SwiftUI

struct MainTabView: View {
    @ObservedObject var vm: GroceryViewModel
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        TabView {
            
            ListsView(vm: vm)
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
            
            GeneratedListView(vm: vm)
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
            
            BudgetView(vm: vm)
                .tabItem {
                    Label("Budget", systemImage: "wallet.pass.fill")
                }

            AIAssistantView(vm: vm)
                .tabItem {
                    Label("Assistant", systemImage: "sparkles")
                }

            ShopsView()
                .tabItem {
                    Label("Shops", systemImage: "map.fill")
                }

            StatsView(vm: vm)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .hideKeyboardOnTap()
        .tint(.blue)
    }
}
