import SwiftUI

// MARK: - ColorTheme Data Model
struct ColorTheme: Codable {
    var primaryColor: String // Hex color string
    var secondaryColor: String
    var accentColor: String
    var backgroundColor: String
    var cardBackgroundColor: String
    var textColor: String
    var eventCategories: [EventCategory]
    
    init() {
        // Default calming birchwood theme with brown undertones
        self.primaryColor = "#8B7355" // Warm brown
        self.secondaryColor = "#D2B48C" // Tan
        self.accentColor = "#A0522D" // Sienna
        self.backgroundColor = "#F5F5DC" // Beige
        self.cardBackgroundColor = "#FAF0E6" // Linen
        self.textColor = "#2F2F2F" // Dark gray
        self.eventCategories = [
            EventCategory(name: "Personal", color: "#8B7355", icon: "person"),
            EventCategory(name: "Church", color: "#A0522D", icon: "cross"),
            EventCategory(name: "School", color: "#6B8E23", icon: "book"),
            EventCategory(name: "Work", color: "#4682B4", icon: "briefcase"),
            EventCategory(name: "Family", color: "#D2691E", icon: "house"),
            EventCategory(name: "Health", color: "#228B22", icon: "heart"),
            EventCategory(name: "Other", color: "#708090", icon: "circle")
        ]
    }
    
    // Convert hex string to Color
    func colorFromHex(_ hex: String) -> Color {
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
    
    // Convert Color to hex string
    func hexFromColor(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb).uppercased()
    }
    
    // Get colors as SwiftUI Colors
    var primary: Color { colorFromHex(primaryColor) }
    var secondary: Color { colorFromHex(secondaryColor) }
    var accent: Color { colorFromHex(accentColor) }
    var background: Color { colorFromHex(backgroundColor) }
    var cardBackground: Color { colorFromHex(cardBackgroundColor) }
    var text: Color { colorFromHex(textColor) }
}

// Global color theme manager
class ColorThemeManager: ObservableObject {
    @Published var currentTheme: ColorTheme {
        didSet {
            saveTheme()
        }
    }
    
    static let shared = ColorThemeManager()
    
    private init() {
        self.currentTheme = ColorTheme()
        if let savedTheme = loadTheme() {
            self.currentTheme = savedTheme
        }
    }
    
    private func saveTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(encoded, forKey: "ColorTheme")
        }
    }
    
    private func loadTheme() -> ColorTheme? {
        if let data = UserDefaults.standard.data(forKey: "ColorTheme"),
           let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) {
            return theme
        }
        return nil
    }
    
    func resetToDefault() {
        currentTheme = ColorTheme()
    }
    
    func getCategoryColor(for categoryName: String) -> Color {
        if let category = currentTheme.eventCategories.first(where: { $0.name == categoryName }) {
            return currentTheme.colorFromHex(category.color)
        }
        return currentTheme.primary
    }
}

// MARK: - Design System
struct DesignSystem {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color.blue
        static let secondary = Color.orange
        static let accent = Color.purple
        
        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Neutral Colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        // Text Colors
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Tab Colors
        static let dashboard = Color.blue
        static let goals = Color.orange
        static let calendar = Color.purple
        static let tasks = Color.green
        static let notes = Color.indigo
        static let settings = Color.gray
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 1000
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.2)
        static let heavy = Color.black.opacity(0.3)
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func shadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Gradient Presets
struct Gradients {
    static let primary = LinearGradient(
        colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondary = LinearGradient(
        colors: [DesignSystem.Colors.secondary, DesignSystem.Colors.secondary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accent = LinearGradient(
        colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Animation Presets
struct Animations {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    static let bounce = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
}