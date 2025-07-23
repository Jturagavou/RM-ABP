import Foundation

// MARK: - Widget Data Sync Status
public enum WidgetSyncStatus: Equatable {
    case success
    case appGroupNotConfigured
    case encodingError(Error)
    case decodingError(Error)
    case noData
    case authenticationMismatch
    
    public static func == (lhs: WidgetSyncStatus, rhs: WidgetSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success),
             (.appGroupNotConfigured, .appGroupNotConfigured),
             (.noData, .noData),
             (.authenticationMismatch, .authenticationMismatch):
            return true
        case (.encodingError(_), .encodingError(_)),
             (.decodingError(_), .decodingError(_)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Widget Data Utilities with Enhanced Error Handling
public struct WidgetDataUtilities {
    // Use shared UserDefaults for widget data synchronization
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.areabook.ios")
    
    // MARK: - App Group Validation
    public static func validateAppGroupConfiguration() -> Bool {
        guard let sharedDefaults = sharedDefaults else {
            print("❌ WidgetDataUtilities: CRITICAL - App group 'group.com.areabook.ios' is NOT configured!")
            print("❌ WidgetDataUtilities: Please ensure App Groups capability is enabled in both main app and widget extension")
            return false
        }
        
        // Test write/read cycle to verify app group is working
        let testKey = "app_group_validation_test"
        let testData = ["timestamp": "\(Date())", "test": "validation"]
        
        do {
            let encoded = try JSONEncoder().encode(testData)
            sharedDefaults.set(encoded, forKey: testKey)
            sharedDefaults.synchronize()
            
            // Try to read it back
            guard let readData = sharedDefaults.data(forKey: testKey),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: readData) else {
                print("❌ WidgetDataUtilities: App group read/write test FAILED")
                return false
            }
            
            // Clean up test data
            sharedDefaults.removeObject(forKey: testKey)
            sharedDefaults.synchronize()
            
            print("✅ WidgetDataUtilities: App group validation PASSED - \(decoded)")
            return true
            
        } catch {
            print("❌ WidgetDataUtilities: App group validation error: \(error)")
            return false
        }
    }
    
    // MARK: - Enhanced Save with Validation
    @discardableResult
    public static func saveData<T: Codable>(_ data: T, forKey key: String) -> WidgetSyncStatus {
        // First validate app group
        guard validateAppGroupConfiguration() else {
            return .appGroupNotConfigured
        }
        
        guard let sharedDefaults = sharedDefaults else {
            return .appGroupNotConfigured
        }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            sharedDefaults.set(encoded, forKey: key)
            sharedDefaults.synchronize()
            
            print("✅ WidgetDataUtilities: Successfully saved data for key '\(key)' - size: \(encoded.count) bytes")
            
            // Validate the data was actually saved
            if let readBack = sharedDefaults.data(forKey: key), readBack.count == encoded.count {
                print("✅ WidgetDataUtilities: Data validation confirmed for key '\(key)'")
                return .success
            } else {
                print("❌ WidgetDataUtilities: Data validation FAILED for key '\(key)' - save may not have worked")
                return .encodingError(NSError(domain: "WidgetDataUtilities", code: 1, userInfo: [NSLocalizedDescriptionKey: "Data validation failed after save"]))
            }
            
        } catch {
            print("❌ WidgetDataUtilities: Failed to save data for key \(key): \(error)")
            return .encodingError(error)
        }
    }
    
    // MARK: - Enhanced Load with Validation
    public static func loadData<T: Codable>(_ type: T.Type, forKey key: String) -> (data: T?, status: WidgetSyncStatus) {
        // First validate app group
        guard validateAppGroupConfiguration() else {
            return (nil, .appGroupNotConfigured)
        }
        
        guard let sharedDefaults = sharedDefaults else {
            return (nil, .appGroupNotConfigured)
        }
        
        guard let data = sharedDefaults.data(forKey: key) else {
            print("⚠️ WidgetDataUtilities: No data found for key '\(key)'")
            return (nil, .noData)
        }
        
        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            print("✅ WidgetDataUtilities: Successfully loaded data for key '\(key)' - size: \(data.count) bytes")
            return (decoded, .success)
        } catch {
            print("❌ WidgetDataUtilities: Failed to decode data for key \(key): \(error)")
            print("❌ WidgetDataUtilities: Data corruption detected - clearing corrupted data")
            
            // Clear corrupted data
            sharedDefaults.removeObject(forKey: key)
            sharedDefaults.synchronize()
            
            return (nil, .decodingError(error))
        }
    }
    
    // MARK: - Legacy Support (for backward compatibility)
    public static func loadData<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let (data, _) = loadData(type, forKey: key)
        return data
    }
    
    // MARK: - Authentication State Management
    public static func saveAuthenticationState(userId: String?, isAuthenticated: Bool) -> WidgetSyncStatus {
        let authState = [
            "userId": userId ?? "",
            "isAuthenticated": isAuthenticated,
            "lastUpdate": Date().timeIntervalSince1970 // Convert Date to TimeInterval for JSON compatibility
        ] as [String : Any]
        
        guard let sharedDefaults = sharedDefaults else {
            return .appGroupNotConfigured
        }
        
        do {
            let encoded = try JSONSerialization.data(withJSONObject: authState)
            sharedDefaults.set(encoded, forKey: "widget_auth_state")
            sharedDefaults.synchronize()
            print("✅ WidgetDataUtilities: Authentication state saved - userId: \(userId ?? "none"), authenticated: \(isAuthenticated)")
            return .success
        } catch {
            print("❌ WidgetDataUtilities: Failed to save auth state: \(error)")
            return .encodingError(error)
        }
    }
    
    public static func loadAuthenticationState() -> (userId: String?, isAuthenticated: Bool, lastUpdate: Date?) {
        guard let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: "widget_auth_state"),
              let authState = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ WidgetDataUtilities: No authentication state found")
            return (nil, false, nil)
        }
        
        let userId = authState["userId"] as? String
        let isAuthenticated = authState["isAuthenticated"] as? Bool ?? false
        
        // Convert TimeInterval back to Date
        var lastUpdate: Date?
        if let timeInterval = authState["lastUpdate"] as? TimeInterval {
            lastUpdate = Date(timeIntervalSince1970: timeInterval)
        }
        
        print("📊 WidgetDataUtilities: Loaded auth state - userId: \(userId ?? "none"), authenticated: \(isAuthenticated)")
        return (userId?.isEmpty == false ? userId : nil, isAuthenticated, lastUpdate)
    }
    
    // MARK: - Data Validation and Health Check
    public static func validateDataIntegrity() -> [String: WidgetSyncStatus] {
        var results: [String: WidgetSyncStatus] = [:]
        
        // Check each data type
        let dataKeys = WidgetDataKeys.allKeys
        
        for key in dataKeys {
            guard let sharedDefaults = sharedDefaults,
                  let data = sharedDefaults.data(forKey: key) else {
                results[key] = .noData
                continue
            }
            
            // Try to parse as generic JSON to check for corruption
            do {
                let _ = try JSONSerialization.jsonObject(with: data)
                results[key] = .success
            } catch {
                results[key] = .decodingError(error)
                // Clear corrupted data
                sharedDefaults.removeObject(forKey: key)
                sharedDefaults.synchronize()
                print("🗑️ WidgetDataUtilities: Cleared corrupted data for key '\(key)'")
            }
        }
        
        return results
    }
    
    public static func clearData(forKey key: String) {
        sharedDefaults?.removeObject(forKey: key)
        sharedDefaults?.synchronize()
        print("🗑️ WidgetDataUtilities: Cleared data for key '\(key)'")
    }
    
    public static func clearAllWidgetData() {
        guard validateAppGroupConfiguration() else {
            print("❌ WidgetDataUtilities: Cannot clear data - app group not configured")
            return
        }
        
        for key in WidgetDataKeys.allKeys {
            clearData(forKey: key)
        }
        
        // Also clear auth state
        sharedDefaults?.removeObject(forKey: "widget_auth_state")
        sharedDefaults?.synchronize()
        
        print("🗑️ WidgetDataUtilities: Cleared all widget data and auth state")
    }
    
    // MARK: - Diagnostic Information
    public static func getDataSizes() -> [String: Int] {
        guard let sharedDefaults = sharedDefaults else {
            return [:]
        }
        
        var sizes: [String: Int] = [:]
        
        for key in WidgetDataKeys.allKeys {
            if let data = sharedDefaults.data(forKey: key) {
                sizes[key] = data.count
            } else {
                sizes[key] = 0
            }
        }
        
        return sizes
    }
    
    public static func getTotalDataSize() -> Int {
        return getDataSizes().values.reduce(0, +)
    }
} 
 