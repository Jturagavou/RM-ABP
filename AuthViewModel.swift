import Foundation
import Firebase
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    init() {
        self.userSession = Auth.auth().currentUser
        
        Task {
            await fetchUser()
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func createUser(withEmail email: String, password: String, fullname: String) async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            let user = User(
                id: result.user.uid,
                fullname: fullname,
                email: email,
                keyIndicators: [],
                accountabilityGroups: [],
                settings: UserSettings()
            )
            
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            
            await fetchUser()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("DEBUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        // Delete user data from Firestore
        try await Firestore.firestore().collection("users").document(user.uid).delete()
        
        // Delete authentication account
        try await user.delete()
        
        self.userSession = nil
        self.currentUser = nil
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            self.currentUser = try snapshot.data(as: User.self)
        } catch {
            print("DEBUG: Failed to fetch user with error \(error.localizedDescription)")
        }
    }
    
    func listenToAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.userSession = user
            }
        }
    }
}