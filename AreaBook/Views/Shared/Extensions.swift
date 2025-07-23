import SwiftUI

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Loading States
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing:16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .cornerRadius(8)
            .shimmer()
    }
}

// MARK: - Haptic Feedback
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer() -> some View {
        self.overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(self)
                .offset(x: -200)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: UUID()
                )
        )
    }
}

// MARK: - Smooth Animations
extension Animation {
    static var smoothAppear: Animation {
        .easeInOut(duration: 0.3)
    }
    
    static var smoothDisappear: Animation {
        .easeInOut(duration: 0.2)
    }
    
    static var springBounce: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    }
}

// MARK: - Toast Notifications
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    enum ToastType {
        case success, error, warning, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing:12) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(type.color)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.smoothDisappear) {
                    isShowing = false
                }
            }
        }
    }
} 