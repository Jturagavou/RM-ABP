import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging

class FirebaseService {
    static let shared = FirebaseService()
    
    let auth: Auth
    let db: Firestore
    let storage: Storage
    let messaging: Messaging?
    
    private init() {
        // Firebase should be configured in the App delegate or main app file
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        self.storage = Storage.storage()
        self.messaging = Messaging.messaging()
        
        setupFirestore()
        setupMessaging()
    }
    
    private func setupFirestore() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    private func setupMessaging() {
        // Configure Firebase Messaging for push notifications
        messaging?.delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func configure() {
        guard FirebaseApp.app() == nil else {
            print("Firebase already configured")
            return
        }
        
        // Check if we have a valid GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["API_KEY"] as? String,
              !apiKey.contains("YOUR_") else {
            print("⚠️ Firebase configuration skipped: GoogleService-Info.plist contains placeholder values")
            print("📝 To enable Firebase, replace placeholder values in GoogleService-Info.plist with real Firebase project values")
            return
        }
        
        FirebaseApp.configure()
        print("Firebase configured successfully")
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
        db.enableNetwork { error in
            if let error = error {
                print("Error enabling network: \(error.localizedDescription)")
            } else {
                print("Network enabled")
            }
        }
    }
    
    func disableNetwork() {
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
        return try await auth.signIn(withEmail: email, password: password)
    }
    
    func createUser(email: String, password: String) async throws -> AuthDataResult {
        return try await auth.createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    func deleteUser() async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        try await user.delete()
    }
}

import UserNotifications
import UIKit