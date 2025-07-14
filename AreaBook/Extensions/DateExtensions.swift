import Foundation
import Firebase

// MARK: - Date Extensions
extension Date {
    /// Returns an ISO8601 formatted string representation of the date
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - JSON Safe Conversion Utilities
/// Recursively converts Firestore data to JSON-safe format
func makeJSONSafe(_ dict: [String: Any]) -> [String: Any] {
    var safe = [String: Any]()
    for (key, value) in dict {
        if let timestamp = value as? Timestamp {
            safe[key] = timestamp.dateValue().iso8601String
        } else if let date = value as? Date {
            safe[key] = date.iso8601String
        } else if let subDict = value as? [String: Any] {
            safe[key] = makeJSONSafe(subDict)
        } else if let array = value as? [Any] {
            safe[key] = array.map { element -> Any in
                if let ts = element as? Timestamp {
                    return ts.dateValue().iso8601String
                } else if let d = element as? Date {
                    return d.iso8601String
                } else if let sd = element as? [String: Any] {
                    return makeJSONSafe(sd)
                } else {
                    return element
                }
            }
        } else if JSONSerialization.isValidJSONObject([key: value]) {
            safe[key] = value
        } else {
            print("⚠️ Skipping non-JSON value for key: \(key), value: \(value)")
        }
    }
    return safe
}