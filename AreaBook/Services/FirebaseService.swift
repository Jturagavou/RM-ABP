import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging

class FirebaseService {
    static let shared = FirebaseService()
    
    private(set) var auth: Auth?
    private(set) var db: Firestore?
    private(set) var storage: Storage?
    private(set) var messaging: Messaging?
    
    private var isConfigured = false
    
    private init() {
        // Don't initialize Firebase services here - wait for configure()
    }
    
    func configure() {
        guard !isConfigured else {
            print("Firebase already configured")
            return
        }
        
        // Check if GoogleService-Info.plist exists and is valid
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let _ = plist["CLIENT_ID"] as? String,
              !((plist["CLIENT_ID"] as? String)?.contains("YOUR_") ?? true) else {
            print("❌ FATAL: GoogleService-Info.plist is missing or contains placeholder values!")
            print("❌ Please download the real file from Firebase Console")
            fatalError("Invalid Firebase configuration. See console for details.")
        }
        
        FirebaseApp.configure()
        
        // Now initialize Firebase services after configuration
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        self.storage = Storage.storage()
        self.messaging = Messaging.messaging()
        
        setupFirestore()
        setupMessaging()
        
        isConfigured = true
        print("✅ Firebase configured successfully")
    }
    
    private func setupFirestore() {
        guard let db = db else { return }
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    private func setupMessaging() {
        guard let messaging = messaging else { return }
        
        // Configure Firebase Messaging for push notifications
        messaging.delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        // Register for remote notifications on main thread
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

// MARK: - Messaging Delegate
extension FirebaseService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}

// MARK: - Notification Center Delegate
extension FirebaseService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Print message ID if available
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message
        print(userInfo)
        
        // Show notification even when app is in foreground
        completionHandler([[.alert, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Print message ID if available
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message
        print(userInfo)
        
        completionHandler()
    }
}

// MARK: - Firestore Extensions
extension FirebaseService {
    func enableNetwork() {
        guard let db = db else { return }
        
        db.enableNetwork { error in
            if let error = error {
                print("Error enabling network: \(error.localizedDescription)")
            } else {
                print("Network enabled")
            }
        }
    }
    
    func disableNetwork() {
        guard let db = db else { return }
        
        db.disableNetwork { error in
            if let error = error {
                print("Error disabling network: \(error.localizedDescription)")
            } else {
                print("Network disabled")
            }
        }
    }
}

// MARK: - Authentication Extensions
extension FirebaseService {
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        guard let auth = auth else {
            throw NSError(domain: "FirebaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        return try await auth.signIn(withEmail: email, password: password)
    }
    
    func createUser(email: String, password: String) async throws -> AuthDataResult {
        guard let auth = auth else {
            throw NSError(domain: "FirebaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        return try await auth.createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        guard let auth = auth else {
            throw NSError(domain: "FirebaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        guard let auth = auth else {
            throw NSError(domain: "FirebaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    func deleteUser() async throws {
        guard let auth = auth else {
            throw NSError(domain: "FirebaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        guard let user = auth.currentUser else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        try await user.delete()
    }
}

import UserNotifications
import UIKit