import Foundation
import Firebase
import FirebaseAuth
import Combine
import WidgetKit
import os.log

class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
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
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
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
                    
                    // TEMPORARILY DISABLED: Clear widget data (might be causing crash)
                    // self.clearWidgetDataOnSignout()
                }
                self?.isLoading = false
            }
        }
        
        os_log("🔐 AuthViewModel: Auth state listener setup complete", log: .default, type: .info)
    }
    
    // MARK: - Widget Data Management
    private func syncAuthenticationStateToWidgets() {
        let status = WidgetDataUtilities.saveAuthenticationState(
            userId: currentUser?.id,
            isAuthenticated: isAuthenticated
        )
        
        switch status {
        case .success:
            os_log("✅ AuthViewModel: Authentication state synced to widgets", log: .default, type: .info)
        case .appGroupNotConfigured:
            os_log("❌ AuthViewModel: CRITICAL - App group not configured for widgets!", log: .default, type: .error)
        default:
            os_log("❌ AuthViewModel: Failed to sync auth state to widgets: %{public}@", log: .default, type: .error, String(describing: status))
        }
    }
    
    private func clearWidgetDataOnSignout() {
        os_log("🔄 AuthViewModel: Clearing widget data due to user signout", log: .default, type: .info)
        
        // Clear all widget data
        WidgetDataUtilities.clearAllWidgetData()
        
        // Sync cleared auth state
        let _ = WidgetDataUtilities.saveAuthenticationState(userId: nil, isAuthenticated: false)
        
        // Force widget reload to show empty state
        WidgetCenter.shared.reloadAllTimelines()
        
        os_log("✅ AuthViewModel: Widget data cleared and timelines reloaded", log: .default, type: .info)
    }
    
    private func loadUserData(userId: String) {
        let db = FirebaseService.shared.db!
        os_log("🔐 AuthViewModel: Accessing Firestore at path: users/%{public}@", log: .default, type: .info, userId)
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    os_log("❌ AuthViewModel: Error loading user data: %{public}@", log: .default, type: .error, error.localizedDescription)
                    self.isLoading = false
                    return
                }
                if let document = document, document.exists {
                    os_log("✅ AuthViewModel: User document exists for user: %{public}@", log: .default, type: .info, userId)
                    
                    // Log raw data for debugging
                    if let data = document.data() {
                        os_log("🔍 AuthViewModel: Raw Firestore data: %{public}@", log: .default, type: .info, String(describing: data))
                    }
                    
                    do {
                        let user = try document.data(as: User.self)
                        os_log("✅ AuthViewModel: Successfully decoded user data for: %{public}@", log: .default, type: .info, user.name)
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.isLoading = false
                        os_log("✅ AuthViewModel: User authentication state updated - isAuthenticated: true", log: .default, type: .info)
                        
                        // FIXED: Sync authentication state to widgets with improved error handling
                        self.syncAuthenticationStateToWidgets()
                    } catch {
                        os_log("❌ AuthViewModel: Failed to decode user data: %{public}@", log: .default, type: .error, error.localizedDescription)
                        os_log("❌ AuthViewModel: Decoding error: %{public}@", log: .default, type: .error, String(describing: error))
                        
                        // Try to create a user document with current Firebase Auth user data
                        guard let firebaseUser = Auth.auth().currentUser else {
                            os_log("❌ AuthViewModel: No Firebase user found when creating document", log: .default, type: .error)
                            self.signOut()
                            self.isLoading = false
                            return
                        }
                        
                        self.createUserDocument(
                            userId: userId,
                            email: firebaseUser.email ?? "",
                            name: firebaseUser.displayName ?? "User",
                            avatar: firebaseUser.photoURL?.absoluteString
                        )
                    }
                } else {
                    os_log("⚠️ AuthViewModel: User document doesn't exist for user: %{public}@", log: .default, type: .error, userId)
                    os_log("⚠️ AuthViewModel: Attempting to create user document for user: %{public}@", log: .default, type: .info, userId)
                    
                    // Get the current Firebase Auth user to create the document
                    guard let firebaseUser = Auth.auth().currentUser else {
                        os_log("❌ AuthViewModel: No Firebase user found when creating document", log: .default, type: .error)
                        self.signOut()
                        self.isLoading = false
                        return
                    }
                    
                    self.createUserDocument(
                        userId: userId,
                        email: firebaseUser.email ?? "",
                        name: firebaseUser.displayName ?? "User",
                        avatar: firebaseUser.photoURL?.absoluteString
                    )
                }
            }
        }
    }

    private func createUserDocument(userId: String, email: String, name: String, avatar: String? = nil) {
        let db = FirebaseService.shared.db!
        let userRef = db.collection("users").document(userId)
        
        let user = User(
            id: userId,
            email: email,
            name: name,
            avatar: avatar,
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
                
                DispatchQueue.main.async {
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
                        os_log("✅ AuthViewModel: User document creation complete - isAuthenticated: true", log: .default, type: .info)
                        
                        // FIXED: Sync authentication state to widgets after user creation
                        self.syncAuthenticationStateToWidgets()
                    }
                }
            }
        } catch {
            os_log("❌ AuthViewModel: Failed to create user document: %{public}@", log: .default, type: .error, error.localizedDescription)
            self.showError("Failed to create user document: \(error.localizedDescription)", suggestion: "Try again or contact support.")
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
                    self?.showError("Failed to sign in. \(error.localizedDescription)", suggestion: "Check your email and password, or try again later.")
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
                    self?.showError("Failed to sign up. \(error.localizedDescription)", suggestion: "Try again or contact support.")
                    return
                }
                
                guard let firebaseUser = result?.user else {
                    os_log("❌ AuthViewModel: Failed to create user", log: .default, type: .error)
                    self?.showError("Failed to create user", suggestion: "Try again or contact support.")
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
                
                self?.createUserDocument(userId: firebaseUser.uid, email: firebaseUser.email ?? "", name: name, avatar: firebaseUser.photoURL?.absoluteString)
            }
        }
    }
    
    func signOut() {
        os_log("🔐 AuthViewModel: Attempting sign out", log: .default, type: .info)
        
        do {
            try Auth.auth().signOut()
            os_log("✅ AuthViewModel: Sign out successful", log: .default, type: .info)
            
            // Clear local state
            currentUser = nil
            isAuthenticated = false
            
            // FIXED: Clear widget data immediately on signout
            clearWidgetDataOnSignout()
            
        } catch {
            os_log("❌ AuthViewModel: Sign out error: %{public}@", log: .default, type: .error, error.localizedDescription)
            showError(error.localizedDescription)
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
                    self?.showError(error.localizedDescription, suggestion: "Check your email address and try again.")
                } else {
                    os_log("✅ AuthViewModel: Password reset email sent successfully", log: .default, type: .info)
                    // For success messages, set the message directly instead of using showError
                    DispatchQueue.main.async {
                        self?.errorMessage = "Password reset email sent successfully"
                        self?.showError = true
                    }
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
    
    private func showError(_ message: String, suggestion: String? = nil) {
        if let suggestion = suggestion {
            errorMessage = "\(message)\nSuggestion: \(suggestion)"
        } else {
            errorMessage = message
        }
        showError = true
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showError = false
        }
    }
    
    func deleteUserAccount(completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else {
            os_log("⚠️ AuthViewModel: No current user for account deletion", log: .default, type: .error)
            completion(false)
            return
        }
        
        os_log("🔐 AuthViewModel: Deleting account for user: %{public}@", log: .default, type: .info, currentUser.id)
        isLoading = true
        
        // First delete the user document from Firestore
        let db = FirebaseService.shared.db!
        db.collection("users").document(currentUser.id).delete { [weak self] error in
            if let error = error {
                os_log("❌ AuthViewModel: Failed to delete user document: %{public}@", log: .default, type: .error, error.localizedDescription)
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.showError("Failed to delete user data: \(error.localizedDescription)", suggestion: "Try again or contact support.")
                    completion(false)
                }
                return
            }
            
            // Then delete the Firebase Auth account
            guard let firebaseUser = Auth.auth().currentUser else {
                os_log("❌ AuthViewModel: No Firebase user found for deletion", log: .default, type: .error)
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.showError("No user account found", suggestion: "Try again or contact support.")
                    completion(false)
                }
                return
            }
            
            firebaseUser.delete { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        os_log("❌ AuthViewModel: Failed to delete Firebase account: %{public}@", log: .default, type: .error, error.localizedDescription)
                        self?.showError("Failed to delete account: \(error.localizedDescription)", suggestion: "Try again or contact support.")
                        completion(false)
                    } else {
                        os_log("✅ AuthViewModel: Account deleted successfully", log: .default, type: .info)
                        self?.currentUser = nil
                        self?.isAuthenticated = false
                        completion(true)
                    }
                }
            }
        }
    }
}