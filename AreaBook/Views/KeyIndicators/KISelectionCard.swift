import SwiftUI

struct KISelectionCard: View {
    let keyIndicator: KeyIndicator
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 12) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: keyIndicator.progressPercentage)
                        .stroke(Color(hex: keyIndicator.color), lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(keyIndicator.currentWeekProgress)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: keyIndicator.color))
                }
                
                // KI Info
                VStack(spacing: 4) {
                    Text(keyIndicator.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text("\(keyIndicator.currentWeekProgress)/\(keyIndicator.weeklyTarget) \(keyIndicator.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Selection Indicator
                HStack {
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .gray)
                        .font(.caption)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: keyIndicator.color).opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: keyIndicator.color) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Color extension for hex colors (if not already available)
extension Color {
    init(hex: String) {
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
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    let sampleKI = KeyIndicator(name: "Daily Exercise", weeklyTarget: 7, unit: "sessions", color: "#3B82F6")
    
    return VStack {
        HStack {
            KISelectionCard(keyIndicator: sampleKI, isSelected: false) { }
            KISelectionCard(keyIndicator: sampleKI, isSelected: true) { }
        }
        .padding()
    }
}