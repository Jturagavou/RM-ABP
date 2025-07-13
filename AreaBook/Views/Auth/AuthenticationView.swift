import SwiftUI

struct AuthenticationView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showingForgotPassword = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("AreaBook")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Your spiritual productivity companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                    
                    // Toggle between Login and Sign Up
                    Picker("Mode", selection: $isLoginMode) {
                        Text("Sign In").tag(true)
                        Text("Sign Up").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Form
                    VStack(spacing: 20) {
                        if !isLoginMode {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !isLoginMode {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Main Action Button
                        Button(action: performAuthAction) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text(isLoginMode ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(authViewModel.isLoading || !isFormValid)
                        
                        if isLoginMode {
                            Button("Forgot Password?") {
                                showingForgotPassword = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .alert("Reset Password", isPresented: $showingForgotPassword) {
                TextField("Email", text: $email)
                Button("Send Reset Email") {
                    authViewModel.resetPassword(email: email)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your email address to receive a password reset link.")
            }
        }
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty && password == confirmPassword && password.count >= 6
        }
    }
    
    private func performAuthAction() {
        if isLoginMode {
            authViewModel.signIn(email: email, password: password)
        } else {
            authViewModel.signUp(email: email, password: password, name: name)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
}