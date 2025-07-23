import SwiftUI
import os.log

struct AuthenticationView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showingForgotPassword = false
    @State private var showingOnboarding = false
    @State private var animateHeader = false
    @State private var animateForm = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Enhanced Header
                        VStack(spacing: 16) {
                            // Animated logo
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .scaleEffect(animateHeader ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateHeader)
                            
                            VStack(spacing: 8) {
                                Text("AreaBook")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text("Your life productivity companion")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.8)
                            }
                        }
                        .padding(.top, 60)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .offset(y: animateHeader ? 0 : 20)
                        
                        // Enhanced Toggle
                        VStack(spacing: 20) {
                            Picker("Mode", selection: $isLoginMode) {
                                Text("Sign In").tag(true)
                                Text("Create Account").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            .scaleEffect(animateForm ? 1.0 : 0.9)
                            
                            // Enhanced Form
                            VStack(spacing: 20) {
                                if !isLoginMode {
                                    TextField("Full Name", text: $name)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)
                                        ))
                                }
                                
                                TextField("Email Address", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                if !isLoginMode {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .move(edge: .bottom).combined(with: .opacity)
                                        ))
                                }
                                
                                // Enhanced Action Button
                                Button(action: performAuthAction) {
                                    HStack(spacing: 12) {
                                        if authViewModel.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: isLoginMode ? "arrow.right.circle.fill" : "person.badge.plus")
                                                .font(.title3)
                                        }
                                        
                                        Text(isLoginMode ? "Sign In" : "Create Account")
                                            .fontWeight(.semibold)
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .disabled(authViewModel.isLoading || !isFormValid)
                                .scaleEffect(animateForm ? 1.0 : 0.95)
                                
                                if isLoginMode {
                                                                    Button("Forgot Password?") {
                                    // HapticManager.shared.lightImpact()
                                    showingForgotPassword = true
                                }
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                    .opacity(animateForm ? 1.0 : 0.0)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .opacity(animateForm ? 1.0 : 0.0)
                        .offset(y: animateForm ? 0 : 30)
                        
                        Spacer(minLength: 50)
                    }
                }
                .navigationBarHidden(true)
            }
            .alert("Reset Password", isPresented: $showingForgotPassword) {
                TextField("Email", text: $email)
                Button("Send Reset Email") {
                    // HapticManager.shared.buttonPressed()
                    authViewModel.resetPassword(email: email)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your email address to receive a password reset link.")
            }
        }
        .onAppear {
            os_log("🔐 AuthenticationView: View appeared", log: .default, type: .info)
            
            // Animate elements on appear
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateForm = true
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
        os_log("🔐 AuthenticationView: performAuthAction called - isLoginMode: %{public}@", log: .default, type: .info, String(describing: isLoginMode))
        os_log("🔐 AuthenticationView: Email: %{public}@", log: .default, type: .info, email)
        os_log("🔐 AuthenticationView: Password length: %{public}d", log: .default, type: .info, password.count)
        
        if isLoginMode {
            os_log("🔐 AuthenticationView: Calling signIn...", log: .default, type: .info)
            authViewModel.signIn(email: email, password: password)
        } else {
            os_log("🔐 AuthenticationView: Calling signUp...", log: .default, type: .info)
            os_log("🔐 AuthenticationView: Name: %{public}@", log: .default, type: .info, name)
            authViewModel.signUp(email: email, password: password, name: name)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel.shared)
}