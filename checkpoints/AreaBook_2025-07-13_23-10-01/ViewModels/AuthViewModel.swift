import Foundation
import Firebase
import FirebaseAuth
import Combine
import os.log

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        os_log("🔐 AuthViewModel: Initializing...", log: .default, type: .info)
        
        // Ensure Firebase is configured before accessing Auth
        if FirebaseApp.app() == nil {
            os_log("⚠️ AuthViewModel: Firebase not configured, configuring now...", log: .default, type: .info)
            FirebaseService.shared.configure()
        }
        
        // Add a small delay to ensure Firebase is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            os_log("🔐 AuthViewModel: Setting up auth state listener...", log: .default, type: .info)
            self?.setupAuthStateListener()
        }
        
        os_log("🔐 AuthViewModel: Initialization complete", log: .default, type: .info)
    }
    
    private func setupAuthStateListener() {
        os_log("🔐 AuthViewModel: Setting up auth state listener...", log: .default, type: .info)
        
        // Ensure Firebase Auth is available
        guard FirebaseApp.app() != nil else {
            os_log("❌ AuthViewModel: Firebase not configured, cannot setup auth listener", log: .default, type: .error)
            return
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                os_log("🔐 AuthViewModel: Auth state changed - User: %{public}@", log: .default, type: .info, user?.uid ?? "nil")
                os_log("🔐 AuthViewModel: User email: %{public}@", log: .default, type: .info, user?.email ?? "nil")
                os_log("🔐 AuthViewModel: User display name: %{public}@", log: .default, type: .info, user?.displayName ?? "nil")
                
                if let user = user {
                    os_log("🔐 AuthViewModel: User is authenticated, loading user data...", log: .default, type: .info)
                    os_log("🔐 AuthViewModel: User UID: %{public}@", log: .default, type: .info, user.uid)
                    self?.loadUserData(userId: user.uid)
                } else {
                    os_log("🔐 AuthViewModel: No user found, clearing state...", log: .default, type: .info)
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
                self?.isLoading = false
            }
        }
        
        os_log("🔐 AuthViewModel: Auth state listener setup complete", log: .default, type: .info)
    }
    
    private func loadUserData(userId: String) {
        let db = FirebaseService.shared.db!
        os_log("🔐 AuthViewModel: Accessing Firestore at path: users/%{public}@", log: .default, type: .info, userId)
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            if let error = error {
                os_log("❌ AuthViewModel: Error loading user data: %{public}@", log: .default, type: .error, error.localizedDescription)
                self.isLoading = false
                return
            }
            if let document = document, document.exists {
                os_log("✅ AuthViewModel: User document exists for user: %{public}@", log: .default, type: .info, userId)
                if let data = document.data() {
                    do {
                        let userData = try JSONSerialization.data(withJSONObject: data)
                        var user = try JSONDecoder().decode(User.self, from: userData)
                        user.lastSeen = Date()
                        
                        os_log("✅ AuthViewModel: User data loaded successfully: %{public}@", log: .default, type: .info, user.name)
                        os_log("✅ AuthViewModel: User ID: %{public}@", log: .default, type: .info, user.id)
                        os_log("✅ AuthViewModel: User email: %{public}@", log: .default, type: .info, user.email)
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.isLoading = false
                        
                        // Update last seen
                        self.updateLastSeen()
                    } catch {
                        os_log("❌ AuthViewModel: Failed to decode user data: %{public}@", log: .default, type: .error, error.localizedDescription)
                        os_log("❌ AuthViewModel: Decoding error: %{public}@", log: .default, type: .error, String(describing: error))
                        self.showError("Failed to decode user data: \(error.localizedDescription)")
                        self.isLoading = false
                    }
                }
            } else {
                os_log("⚠️ AuthViewModel: User document doesn't exist for user: %{public}@", log: .default, type: .error, userId)
                os_log("⚠️ AuthViewModel: Attempting to create user document for user: %{public}@", log: .default, type: .info, userId)
                self.createUserDocument(userId: userId)
            }
        }
    }

    private func createUserDocument(userId: String) {
        let db = FirebaseService.shared.db!
        let userRef = db.collection("users").document(userId)
        
        // Get the current Firebase Auth user to get email and other info
        guard let firebaseUser = Auth.auth().currentUser else {
            os_log("❌ AuthViewModel: No Firebase user found when creating document", log: .default, type: .error)
            self.signOut()
            self.isLoading = false
            return
        }
        
        let user = User(
            id: userId,
            email: firebaseUser.email ?? "",
            name: firebaseUser.displayName ?? "",
            avatar: firebaseUser.photoURL?.absoluteString,
            createdAt: Date(),
            lastSeen: Date(),
            settings: UserSettings()
        )
        
        do {
            let userData = try JSONEncoder().encode(user)
            let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]
            
            os_log("🔐 AuthViewModel: Writing to Firestore at path: users/%{public}@", log: .default, type: .info, userId)
            os_log("🔐 AuthViewModel: Data keys being written: %{public}@", log: .default, type: .info, String(describing: userDict.keys.sorted()))
            
            userRef.setData(userDict) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    os_log("❌ AuthViewModel: Error creating user document: %{public}@", log: .default, type: .error, error.localizedDescription)
                    // Only sign out if we fail to create the document
                    self.signOut()
                    self.isLoading = false
                } else {
                    os_log("✅ AuthViewModel: Successfully created user document for user: %{public}@", log: .default, type: .info, userId)
                    // Set the current user and authenticated state
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isLoading = false
                    os_log("✅ AuthViewModel: User document creation complete", log: .default, type: .info)
                }
            }
        } catch {
            os_log("❌ AuthViewModel: Failed to create user document: %{public}@", log: .default, type: .error, error.localizedDescription)
            self.showError("Failed to create user document: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
    
    func signIn(email: String, password: String) {
        os_log("🔐 AuthViewModel: Attempting sign in for: %{public}@", log: .default, type: .info, email)
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    os_log("❌ AuthViewModel: Sign in error: %{public}@", log: .default, type: .error, error.localizedDescription)
                    os_log("❌ AuthViewModel: Error code: %{public}d", log: .default, type: .error, error._code)
                    self?.showError(error.localizedDescription)
                } else {
                    os_log("✅ AuthViewModel: Sign in successful", log: .default, type: .info)
                    // User data will be loaded automatically by the auth state listener
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) {
        os_log("🔐 AuthViewModel: Attempting sign up for: %{public}@", log: .default, type: .info, email)
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    os_log("❌ AuthViewModel: Sign up error: %{public}@", log: .default, type: .error, error.localizedDescription)
                    os_log("❌ AuthViewModel: Error code: %{public}d", log: .default, type: .error, error._code)
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let firebaseUser = result?.user else {
                    os_log("❌ AuthViewModel: Failed to create user", log: .default, type: .error)
                    self?.showError("Failed to create user")
                    return
                }
                
                os_log("✅ AuthViewModel: User created successfully: %{public}@", log: .default, type: .info, firebaseUser.uid)
                
                // Update display name
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        os_log("⚠️ AuthViewModel: Failed to update display name: %{public}@", log: .default, type: .error, error.localizedDescription)
                    } else {
                        os_log("✅ AuthViewModel: Display name updated successfully", log: .default, type: .info)
                    }
                }
                
                self?.createUserDocument(userId: firebaseUser.uid)
            }
        }
    }
    
    func signOut() {
        os_log("🔐 AuthViewModel: Signing out...", log: .default, type: .info)
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            os_log("✅ AuthViewModel: Sign out successful", log: .default, type: .info)
        } catch {
            os_log("❌ AuthViewModel: Failed to sign out: %{public}@", log: .default, type: .error, error.localizedDescription)
            showError("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    func resetPassword(email: String) {
        os_log("🔐 AuthViewModel: Resetting password for: %{public}@", log: .default, type: .info, email)
        isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    os_log("❌ AuthViewModel: Password reset error: %{public}@", log: .default, type: .error, error.localizedDescription)
                    self?.showError(error.localizedDescription)
                } else {
                    os_log("✅ AuthViewModel: Password reset email sent successfully", log: .default, type: .info)
                    self?.showError("Password reset email sent successfully", isError: false)
                }
            }
        }
    }
    
    func updateProfile(name: String) {
        guard let currentUser = currentUser else {
            os_log("⚠️ AuthViewModel: No current user for profile update", log: .default, type: .error)
            return
        }
        
        os_log("🔐 AuthViewModel: Updating profile for user: %{public}@", log: .default, type: .info, currentUser.id)
        isLoading = true
        
        let db = FirebaseService.shared.db!
        db.collection("users").document(currentUser.id).updateData([
            "name": name
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    os_log("❌ AuthViewModel: Profile update error: %{public}@", log: .default, type: .error, error.localizedDescription)
                    self?.showError(error.localizedDescription)
                } else {
                    os_log("✅ AuthViewModel: Profile updated successfully", log: .default, type: .info)
                    self?.currentUser?.name = name
                }
            }
        }
    }
    
    private func updateLastSeen() {
        guard let currentUser = currentUser else { return }
        
        os_log("🔐 AuthViewModel: Updating last seen for user: %{public}@", log: .default, type: .info, currentUser.id)
        let db = FirebaseService.shared.db!
        db.collection("users").document(currentUser.id).updateData([
            "lastSeen": Date()
        ]) { error in
            if let error = error {
                os_log("⚠️ AuthViewModel: Failed to update last seen: %{public}@", log: .default, type: .error, error.localizedDescription)
            } else {
                os_log("✅ AuthViewModel: Last seen updated successfully", log: .default, type: .info)
            }
        }
    }
    
    private func showError(_ message: String, isError: Bool = true) {
        errorMessage = message
        showError = true
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showError = false
        }
    }
}