import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullname = ""
    @State private var confirmPassword = ""
    @State private var isSignUpMode = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("AreaBook")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your spiritual growth")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Form Fields
                VStack(spacing: 16) {
                    if isSignUpMode {
                        CustomTextField(
                            text: $fullname,
                            placeholder: "Full Name",
                            icon: "person.fill"
                        )
                    }
                    
                    CustomTextField(
                        text: $email,
                        placeholder: "Email",
                        icon: "envelope.fill"
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    CustomSecureField(
                        text: $password,
                        placeholder: "Password",
                        icon: "lock.fill"
                    )
                    
                    if isSignUpMode {
                        CustomSecureField(
                            text: $confirmPassword,
                            placeholder: "Confirm Password",
                            icon: "lock.fill"
                        )
                    }
                }
                .padding(.horizontal)
                
                // Action Button
                Button(action: handleAuthAction) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text(isSignUpMode ? "Sign Up" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Toggle Sign In/Sign Up
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSignUpMode.toggle()
                        clearForm()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Text(isSignUpMode ? "Sign In" : "Sign Up")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 16)
                
                Spacer()
                
                // Version info
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUpMode {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   !fullname.isEmpty &&
                   !confirmPassword.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6 &&
                   email.contains("@")
        } else {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   email.contains("@")
        }
    }
    
    private func handleAuthAction() {
        Task {
            do {
                if isSignUpMode {
                    try await authViewModel.createUser(
                        withEmail: email,
                        password: password,
                        fullname: fullname
                    )
                } else {
                    try await authViewModel.signIn(
                        withEmail: email,
                        password: password
                    )
                }
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        fullname = ""
        confirmPassword = ""
    }
}

// Custom Text Field Component
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Custom Secure Field Component
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}