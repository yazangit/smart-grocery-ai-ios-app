import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GroceryViewModel()
    @State private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView(vm: vm, isLoggedIn: $isLoggedIn)
            } else {
                LoginView(vm: vm, isLoggedIn: $isLoggedIn)
            }
        }
        .preferredColorScheme(.dark)
    }
}
