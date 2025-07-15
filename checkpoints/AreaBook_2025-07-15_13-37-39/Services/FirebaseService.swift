import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import os.log

class FirebaseService: NSObject {
    static let shared = FirebaseService()
    
    var auth: Auth!
    var db: Firestore!
    var storage: Storage!
    var messaging: Messaging?
    
    private override init() {
        super.init()
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
        os_log("[FirebaseService] configure() called", log: .default, type: .info)
        
        // Check if Firebase is already configured
        guard FirebaseApp.app() == nil else {
            os_log("✅ FirebaseService: Firebase already configured", log: .default, type: .info)
            return
        }
        
        do {
            // Configure Firebase
            FirebaseApp.configure()
            os_log("✅ FirebaseService: FirebaseApp.configure() completed", log: .default, type: .info)
            
            // Initialize Firebase services after configuration
            self.auth = Auth.auth()
            self.db = Firestore.firestore()
            self.storage = Storage.storage()
            self.messaging = Messaging.messaging()
            
            os_log("✅ FirebaseService: All Firebase services initialized", log: .default, type: .info)
            
            setupFirestore()
            setupMessaging()
            
            os_log("✅ FirebaseService: Firebase configured successfully", log: .default, type: .info)
        } catch {
            os_log("❌ FirebaseService: Error configuring Firebase: %{public}@", log: .default, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - Messaging Delegate
extension FirebaseService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        os_log("Firebase registration token: %{public}@", log: .default, type: .info, String(describing: fcmToken))
        
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
            os_log("Message ID: %{public}@", log: .default, type: .info, String(describing: messageID))
        }
        
        // Print full message
        os_log("Full message: %{public}@", log: .default, type: .info, String(describing: userInfo))
        
        // Show notification even when app is in foreground
        completionHandler([[.alert, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Print message ID if available
        if let messageID = userInfo["gcm.message_id"] {
            os_log("Message ID: %{public}@", log: .default, type: .info, String(describing: messageID))
        }
        
        // Print full message
        os_log("Full message: %{public}@", log: .default, type: .info, String(describing: userInfo))
        
        completionHandler()
    }
}

// MARK: - Firestore Extensions
extension FirebaseService {
    func enableNetwork() {
        db.enableNetwork { error in
            if let error = error {
                os_log("Error enabling network: %{public}@", log: .default, type: .error, error.localizedDescription)
            } else {
                os_log("Network enabled", log: .default, type: .info)
            }
        }
    }
    
    func disableNetwork() {
        db.disableNetwork { error in
            if let error = error {
                os_log("Error disabling network: %{public}@", log: .default, type: .error, error.localizedDescription)
            } else {
                os_log("Network disabled", log: .default, type: .info)
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