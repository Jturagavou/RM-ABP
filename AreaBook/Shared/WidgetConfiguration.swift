import Foundation

public struct AppWidgetConfiguration: Codable {
    public var enabledFeatures: [String] = []
    public var lastSync: Date = Date()
    public var widgetPreferences: WidgetPreferences = WidgetPreferences()
    
    public init(enabledFeatures: [String] = [], lastSync: Date = Date(), widgetPreferences: WidgetPreferences = WidgetPreferences()) {
        self.enabledFeatures = enabledFeatures
        self.lastSync = lastSync
        self.widgetPreferences = widgetPreferences
    }
} 