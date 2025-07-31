import Foundation
import SwiftUI
import CoreLocation

// MARK: - Automatic Theme Manager
class AutomaticThemeManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = AutomaticThemeManager()
    
    @Published var currentTheme: ExtendedColorTheme
    @Published var themeMode: ThemeMode = .system
    @Published var automaticSwitching: Bool = false
    @Published var scheduleSettings: ThemeScheduleSettings = ThemeScheduleSettings()
    @Published var locationBasedThemes: Bool = false
    
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private var themeTimer: Timer?
    
    // Pre-built themes
    static let prebuiltThemes: [ExtendedColorTheme] = [
        .defaultLight,
        .defaultDark,
        .oceanBreeze,
        .forestGreen,
        .sunset,
        .midnight,
        .lavender,
        .autumn,
        .minimalist,
        .vibrant
    ]
    
    override init() {
        self.currentTheme = Self.prebuiltThemes[0]
        super.init()
        
        setupLocationManager()
        loadSettings()
        startAutomaticThemeManagement()
    }
    
    // MARK: - Theme Management
    
    func setTheme(_ theme: ExtendedColorTheme) {
        currentTheme = theme
        saveCurrentTheme()
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        saveSettings()
        applyThemeForCurrentMode()
    }
    
    func toggleAutomaticSwitching() {
        automaticSwitching.toggle()
        saveSettings()
        
        if automaticSwitching {
            startAutomaticThemeManagement()
        } else {
            stopAutomaticThemeManagement()
        }
    }
    
    private func applyThemeForCurrentMode() {
        switch themeMode {
        case .system:
            // Use system appearance
            applySystemTheme()
        case .light:
            setTheme(.defaultLight)
        case .dark:
            setTheme(.defaultDark)
        case .automatic:
            applyAutomaticTheme()
        case .custom(let theme):
            setTheme(theme)
        }
    }
    
    private func applySystemTheme() {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        setTheme(isDarkMode ? .defaultDark : .defaultLight)
    }
    
    private func applyAutomaticTheme() {
        if automaticSwitching {
            let currentHour = Calendar.current.component(.hour, from: Date())
            
            if scheduleSettings.useCustomSchedule {
                applyScheduledTheme(currentHour: currentHour)
            } else {
                applyTimeBasedTheme(currentHour: currentHour)
            }
        } else {
            applySystemTheme()
        }
    }
    
    private func applyTimeBasedTheme(currentHour: Int) {
        switch currentHour {
        case 6..<12:  // Morning
            setTheme(.defaultLight)
        case 12..<17: // Afternoon
            setTheme(.oceanBreeze)
        case 17..<20: // Evening
            setTheme(.sunset)
        default:      // Night
            setTheme(.midnight)
        }
    }
    
    private func applyScheduledTheme(currentHour: Int) {
        let settings = scheduleSettings
        
        if currentHour >= settings.lightThemeStart && currentHour < settings.darkThemeStart {
            setTheme(settings.lightTheme)
        } else {
            setTheme(settings.darkTheme)
        }
    }
    
    // MARK: - Location-Based Themes
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func enableLocationBasedThemes() {
        locationBasedThemes = true
        saveSettings()
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            print("Location access denied for theme management")
        }
    }
    
    func disableLocationBasedThemes() {
        locationBasedThemes = false
        saveSettings()
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, locationBasedThemes else { return }
        
        determineThemeBasedOnLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if locationBasedThemes {
                locationManager.requestLocation()
            }
        case .denied, .restricted:
            disableLocationBasedThemes()
        default:
            break
        }
    }
    
    private func determineThemeBasedOnLocation(_ location: CLLocation) {
        // Simplified location-based theme logic
        // In a real app, you might use weather APIs, geographic regions, etc.
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                self?.applyLocationBasedTheme(for: placemark)
            }
        }
    }
    
    private func applyLocationBasedTheme(for placemark: CLPlacemark) {
        // Example logic based on location characteristics
        if let ocean = placemark.ocean, !ocean.isEmpty {
            setTheme(.oceanBreeze)
        } else if let area = placemark.areasOfInterest?.first,
                  area.lowercased().contains("park") || area.lowercased().contains("forest") {
            setTheme(.forestGreen)
        } else if let timeZone = placemark.timeZone {
            // Adjust theme based on local time zone
            let localHour = Calendar.current.component(.hour, from: Date())
            applyTimeBasedTheme(currentHour: localHour)
        }
    }
    
    // MARK: - Automatic Management
    
    private func startAutomaticThemeManagement() {
        stopAutomaticThemeManagement()
        
        guard automaticSwitching else { return }
        
        // Check every hour for theme updates
        themeTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.applyAutomaticTheme()
        }
        
        // Apply immediately
        applyAutomaticTheme()
    }
    
    private func stopAutomaticThemeManagement() {
        themeTimer?.invalidate()
        themeTimer = nil
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        let settings = ThemeManagerSettings(
            themeMode: themeMode,
            automaticSwitching: automaticSwitching,
            scheduleSettings: scheduleSettings,
            locationBasedThemes: locationBasedThemes
        )
        
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: "ThemeManagerSettings")
        }
    }
    
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: "ThemeManagerSettings"),
              let settings = try? JSONDecoder().decode(ThemeManagerSettings.self, from: data) else {
            return
        }
        
        themeMode = settings.themeMode
        automaticSwitching = settings.automaticSwitching
        scheduleSettings = settings.scheduleSettings
        locationBasedThemes = settings.locationBasedThemes
    }
    
    private func saveCurrentTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            userDefaults.set(encoded, forKey: "CurrentTheme")
        }
    }
    
    private func loadCurrentTheme() {
        guard let data = userDefaults.data(forKey: "CurrentTheme"),
              let theme = try? JSONDecoder().decode(ExtendedColorTheme.self, from: data) else {
            return
        }
        
        currentTheme = theme
    }
}

// MARK: - Extended Color Theme

struct ExtendedColorTheme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let primaryColor: String
    let secondaryColor: String
    let accentColor: String
    let backgroundColor: String
    let cardBackgroundColor: String
    let textColor: String
    let isDarkMode: Bool
    let eventCategories: [EventCategory]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        primaryColor: String,
        secondaryColor: String,
        accentColor: String,
        backgroundColor: String,
        cardBackgroundColor: String,
        textColor: String,
        isDarkMode: Bool = false,
        eventCategories: [EventCategory] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.cardBackgroundColor = cardBackgroundColor
        self.textColor = textColor
        self.isDarkMode = isDarkMode
        self.eventCategories = eventCategories.isEmpty ? Self.defaultEventCategories : eventCategories
    }
    
    // Convert to SwiftUI Colors
    var primary: Color { colorFromHex(primaryColor) }
    var secondary: Color { colorFromHex(secondaryColor) }
    var accent: Color { colorFromHex(accentColor) }
    var background: Color { colorFromHex(backgroundColor) }
    var cardBackground: Color { colorFromHex(cardBackgroundColor) }
    var text: Color { colorFromHex(textColor) }
    
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let defaultEventCategories: [EventCategory] = [
        EventCategory(name: "Personal", color: "#8B7355", icon: "person"),
        EventCategory(name: "Work", color: "#4682B4", icon: "briefcase"),
        EventCategory(name: "Health", color: "#228B22", icon: "heart"),
        EventCategory(name: "Family", color: "#D2691E", icon: "house"),
        EventCategory(name: "Other", color: "#708090", icon: "circle")
    ]
}

// MARK: - Pre-built Themes

extension ExtendedColorTheme {
    static let defaultLight = ExtendedColorTheme(
        name: "Default Light",
        description: "Clean and bright theme for everyday use",
        primaryColor: "#007AFF",
        secondaryColor: "#6C7B7F",
        accentColor: "#FF3B30",
        backgroundColor: "#FFFFFF",
        cardBackgroundColor: "#F8F9FA",
        textColor: "#000000",
        isDarkMode: false
    )
    
    static let defaultDark = ExtendedColorTheme(
        name: "Default Dark",
        description: "Elegant dark theme for low-light environments",
        primaryColor: "#0A84FF",
        secondaryColor: "#8E8E93",
        accentColor: "#FF453A",
        backgroundColor: "#000000",
        cardBackgroundColor: "#1C1C1E",
        textColor: "#FFFFFF",
        isDarkMode: true
    )
    
    static let oceanBreeze = ExtendedColorTheme(
        name: "Ocean Breeze",
        description: "Calming blues and teals inspired by the ocean",
        primaryColor: "#006994",
        secondaryColor: "#4A90A4",
        accentColor: "#47B5FF",
        backgroundColor: "#F0F8FF",
        cardBackgroundColor: "#E6F3FF",
        textColor: "#2C5F7C",
        isDarkMode: false
    )
    
    static let forestGreen = ExtendedColorTheme(
        name: "Forest Green",
        description: "Natural greens for a peaceful, organic feel",
        primaryColor: "#228B22",
        secondaryColor: "#6B8E23",
        accentColor: "#32CD32",
        backgroundColor: "#F5F5DC",
        cardBackgroundColor: "#F0F8E8",
        textColor: "#2F4F2F",
        isDarkMode: false
    )
    
    static let sunset = ExtendedColorTheme(
        name: "Sunset",
        description: "Warm oranges and purples of a beautiful sunset",
        primaryColor: "#FF6347",
        secondaryColor: "#DA70D6",
        accentColor: "#FFD700",
        backgroundColor: "#FFF8DC",
        cardBackgroundColor: "#FFEFD5",
        textColor: "#8B4513",
        isDarkMode: false
    )
    
    static let midnight = ExtendedColorTheme(
        name: "Midnight",
        description: "Deep blues and purples for late-night focus",
        primaryColor: "#4169E1",
        secondaryColor: "#6A5ACD",
        accentColor: "#9370DB",
        backgroundColor: "#191970",
        cardBackgroundColor: "#1E1E3F",
        textColor: "#E6E6FA",
        isDarkMode: true
    )
    
    static let lavender = ExtendedColorTheme(
        name: "Lavender",
        description: "Soft purples and lilacs for a gentle experience",
        primaryColor: "#9966CC",
        secondaryColor: "#DDA0DD",
        accentColor: "#EE82EE",
        backgroundColor: "#F8F8FF",
        cardBackgroundColor: "#F0E6FF",
        textColor: "#4B0082",
        isDarkMode: false
    )
    
    static let autumn = ExtendedColorTheme(
        name: "Autumn",
        description: "Rich browns and oranges of fall foliage",
        primaryColor: "#A0522D",
        secondaryColor: "#CD853F",
        accentColor: "#FF8C00",
        backgroundColor: "#FDF5E6",
        cardBackgroundColor: "#F5DEB3",
        textColor: "#8B4513",
        isDarkMode: false
    )
    
    static let minimalist = ExtendedColorTheme(
        name: "Minimalist",
        description: "Simple grays and whites for distraction-free focus",
        primaryColor: "#696969",
        secondaryColor: "#A9A9A9",
        accentColor: "#000000",
        backgroundColor: "#FFFFFF",
        cardBackgroundColor: "#FAFAFA",
        textColor: "#2F2F2F",
        isDarkMode: false
    )
    
    static let vibrant = ExtendedColorTheme(
        name: "Vibrant",
        description: "Bold and energetic colors for motivation",
        primaryColor: "#FF1493",
        secondaryColor: "#00CED1",
        accentColor: "#FFD700",
        backgroundColor: "#FFFFFF",
        cardBackgroundColor: "#FFFAF0",
        textColor: "#2F2F2F",
        isDarkMode: false
    )
}

// MARK: - Supporting Models

enum ThemeMode: Codable {
    case system
    case light
    case dark
    case automatic
    case custom(ExtendedColorTheme)
}

struct ThemeScheduleSettings: Codable {
    var useCustomSchedule: Bool = false
    var lightThemeStart: Int = 6  // 6 AM
    var darkThemeStart: Int = 18  // 6 PM
    var lightTheme: ExtendedColorTheme = .defaultLight
    var darkTheme: ExtendedColorTheme = .defaultDark
}

struct ThemeManagerSettings: Codable {
    let themeMode: ThemeMode
    let automaticSwitching: Bool
    let scheduleSettings: ThemeScheduleSettings
    let locationBasedThemes: Bool
}

struct EventCategory: Codable {
    let name: String
    let color: String
    let icon: String
}