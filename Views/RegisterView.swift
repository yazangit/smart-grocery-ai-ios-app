import SwiftUI
import FirebaseAuth

struct RegisterView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {

                Spacer()

                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Create Account")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                VStack(spacing: 16) {

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(16)
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(16)
                        .foregroundColor(.white)
                }

                Button {
                    hideKeyboard()
                    Auth.auth().createUser(withEmail: email, password: password) { result, error in

                        if let error = error {
                            errorMessage = error.localizedDescription
                            return
                        }

                        dismiss()
                    }

                } label: {

                    Text("Create Account")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                }
                .disabled(email.isEmpty || password.isEmpty)
                .opacity(email.isEmpty || password.isEmpty ? 0.45 : 1)

                if !errorMessage.isEmpty {

                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(24)
        }
        .hideKeyboardOnTap()
    }
}
