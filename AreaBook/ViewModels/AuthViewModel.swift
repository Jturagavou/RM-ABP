import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("🔐 AuthViewModel: Initializing...")
        setupAuthStateListener()
        print("🔐 AuthViewModel: Initialization complete")
    }
    
    private func setupAuthStateListener() {
        print("🔐 AuthViewModel: Setting up auth state listener...")
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    print("🔐 AuthViewModel: Auth state changed - User: \(user.uid)")
                    print("🔐 AuthViewModel: User email: \(user.email ?? "nil")")
                    print("🔐 AuthViewModel: User display name: \(user.displayName ?? "nil")")
                    print("🔐 AuthViewModel: User is authenticated, loading user data...")
                    self?.loadUserData(for: user)
                } else {
                    print("🔐 AuthViewModel: Auth state changed - No user")
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
                self?.isLoading = false
            }
        }
        print("🔐 AuthViewModel: Auth state listener setup complete")
    }
    
    private func loadUserData(for firebaseUser: FirebaseUser) {
        print("🔐 AuthViewModel: User UID: \(firebaseUser.uid)")
        isLoading = true
        
        let db = Firestore.firestore()
        let userDocPath = "users/\(firebaseUser.uid)"
        print("🔐 AuthViewModel: Accessing Firestore at path: \(userDocPath)")
        
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ AuthViewModel: Firestore error: \(error.localizedDescription)")
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("🔐 AuthViewModel: User document doesn't exist, creating new one...")
                    // Create new user document if it doesn't exist
                    self?.createUserDocument(for: firebaseUser)
                    return
                }
                
                print("✅ AuthViewModel: User document exists for user: \(firebaseUser.uid)")
                
                do {
                    // Handle Firestore data conversion
                    let user = try self?.parseUserFromFirestore(data: data, uid: firebaseUser.uid)
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    
                    print("✅ AuthViewModel: User authenticated successfully")
                    print("✅ AuthViewModel: User name: '\(user?.name ?? "nil")', email: '\(user?.email ?? "nil")'")
                    
                    // Update last seen
                    self?.updateLastSeen()
                } catch {
                    print("❌ AuthViewModel: Failed to parse user data: \(error.localizedDescription)")
                    print("❌ AuthViewModel: Raw data: \(data)")
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
    
    private func parseUserFromFirestore(data: [String: Any], uid: String) throws -> User {
        print("🔐 AuthViewModel: Parsing user data from Firestore...")
        
        // Extract basic fields with safe defaults
        let email = data["email"] as? String ?? ""
        let name = data["name"] as? String ?? ""
        let avatar = data["avatar"] as? String
        
        // Handle Firestore Timestamp for createdAt
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let timeInterval = data["createdAt"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: timeInterval)
        } else {
            createdAt = Date()
        }
        
        // Handle Firestore Timestamp for lastSeen
        let lastSeen: Date
        if let timestamp = data["lastSeen"] as? Timestamp {
            lastSeen = timestamp.dateValue()
        } else if let timeInterval = data["lastSeen"] as? TimeInterval {
            lastSeen = Date(timeIntervalSince1970: timeInterval)
        } else {
            lastSeen = Date()
        }
        
        // Parse settings
        let settings: UserSettings
        if let settingsData = data["settings"] as? [String: Any] {
            settings = parseUserSettings(from: settingsData)
        } else {
            settings = UserSettings()
        }
        
        print("✅ AuthViewModel: User data parsed successfully")
        print("✅ AuthViewModel: User name: '\(name)', email: '\(email)'")
        
        return User(
            id: uid,
            email: email,
            name: name,
            avatar: avatar,
            createdAt: createdAt,
            lastSeen: lastSeen,
            settings: settings
        )
    }
    
    private func parseUserSettings(from data: [String: Any]) -> UserSettings {
        var settings = UserSettings()
        
        if let defaultCalendarView = data["defaultCalendarView"] as? String,
           let calendarViewType = CalendarViewType(rawValue: defaultCalendarView) {
            settings.defaultCalendarView = calendarViewType
        }
        
        if let defaultTaskView = data["defaultTaskView"] as? String,
           let taskViewType = TaskViewType(rawValue: defaultTaskView) {
            settings.defaultTaskView = taskViewType
        }
        
        if let eventColorScheme = data["eventColorScheme"] as? [String: String] {
            settings.eventColorScheme = eventColorScheme
        }
        
        if let notificationsEnabled = data["notificationsEnabled"] as? Bool {
            settings.notificationsEnabled = notificationsEnabled
        }
        
        if let pushNotifications = data["pushNotifications"] as? Bool {
            settings.pushNotifications = pushNotifications
        }
        
        if let dailyKIReviewTime = data["dailyKIReviewTime"] as? String {
            settings.dailyKIReviewTime = dailyKIReviewTime
        }
        
        return settings
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