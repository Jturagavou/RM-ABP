import Foundation
import Firebase
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        // Check if Firebase is configured before setting up auth listener
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured, using mock authentication")
            // For testing without Firebase, set a mock authenticated state
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.currentUser = User(
                    id: "mock-user-id",
                    email: "test@example.com",
                    name: "Test User",
                    avatar: nil,
                    createdAt: Date(),
                    lastSeen: Date(),
                    settings: UserSettings()
                )
                self.isLoading = false
            }
            return
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.loadUserData(for: user)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
                self?.isLoading = false
            }
        }
    }
    
    private func loadUserData(for firebaseUser: FirebaseUser) {
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    // Create new user document if it doesn't exist
                    self?.createUserDocument(for: firebaseUser)
                    return
                }
                
                do {
                    let userData = try JSONSerialization.data(withJSONObject: data)
                    var user = try JSONDecoder().decode(User.self, from: userData)
                    user.lastSeen = Date()
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    
                    // Update last seen
                    self?.updateLastSeen()
                } catch {
                    self?.showError("Failed to decode user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createUserDocument(for firebaseUser: FirebaseUser) {
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            name: firebaseUser.displayName ?? "",
            avatar: firebaseUser.photoURL?.absoluteString,
            createdAt: Date(),
            lastSeen: Date(),
            settings: UserSettings()
        )
        
        let db = Firestore.firestore()
        do {
            let userData = try JSONEncoder().encode(user)
            let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]
            
            db.collection("users").document(firebaseUser.uid).setData(userDict) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showError(error.localizedDescription)
                    } else {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                    }
                }
            }
        } catch {
            showError("Failed to create user document: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(error.localizedDescription)
                } else {
                    // User data will be loaded automatically by the auth state listener
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let firebaseUser = result?.user else {
                    self?.showError("Failed to create user")
                    return
                }
                
                // Update display name
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Failed to update display name: \(error.localizedDescription)")
                    }
                }
                
                // User document will be created automatically by loadUserData
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            showError("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(error.localizedDescription)
                } else {
                    self?.showError("Password reset email sent successfully", isError: false)
                }
            }
        }
    }
    
    func updateProfile(name: String) {
        guard let currentUser = currentUser else { return }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.id).updateData([
            "name": name,
            "updatedAt": Date()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(error.localizedDescription)
                } else {
                    self?.currentUser?.name = name
                }
            }
        }
    }
    
    private func updateLastSeen() {
        guard let currentUser = currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.id).updateData([
            "lastSeen": Date()
        ])
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