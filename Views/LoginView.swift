import SwiftUI

struct LoginView: View {
    
    @ObservedObject var vm: GroceryViewModel
    @Binding var isLoggedIn: Bool
    
    @State private var email = "test@test.com"
    @State private var password = "123456"
    @State private var errorMessage = ""
    @State private var isRegistering = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 28) {
                Spacer()
                
                VStack(spacing: 14) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(.blue)
                    
                    Text("Smart Grocery")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    
                    Text("Plan smarter. Shop faster.")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 14) {
                    AppTextField(
                        title: "Email",
                        text: $email,
                        systemImage: "envelope.fill"
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    AppSecureField(
                        title: "Password",
                        text: $password,
                        systemImage: "lock.fill"
                    )
                    
                    Button {
                        hideKeyboard()
                        
                        vm.signIn(email: email, password: password) { success, error in
                            if success {
                                vm.fetchLists()
                                vm.fetchShoppingSessions()
                                isLoggedIn = true
                            } else {
                                errorMessage = error ?? "Login failed"
                            }
                        }
                    } label: {
                        Text("Log In")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.45 : 1)
                    
                    Button {
                        hideKeyboard()
                        isRegistering = true
                    } label: {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.08))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 24)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .hideKeyboardOnTap()
        .sheet(isPresented: $isRegistering) {
            RegisterView()
        }
    }
}
