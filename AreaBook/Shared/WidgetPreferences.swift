import Foundation

public struct WidgetPreferences: Codable {
    public var favoriteWidgets: [String] = []
    public var refreshInterval: Int = 15 // minutes
    public var showNotifications: Bool = true
    public var widgetTheme: WidgetTheme = .system
    
    public enum WidgetTheme: String, CaseIterable, Codable {
        case system = "system"
        case light = "light"
        case dark = "dark"
    }
    
    public init(favoriteWidgets: [String] = [], refreshInterval: Int = 15, showNotifications: Bool = true, widgetTheme: WidgetTheme = .system) {
        self.favoriteWidgets = favoriteWidgets
        self.refreshInterval = refreshInterval
        self.showNotifications = showNotifications
        self.widgetTheme = widgetTheme
    }
} 