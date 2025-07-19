import SwiftUI

// MARK: - Smart Tips Manager
class SmartTipsManager: ObservableObject {
    static let shared = SmartTipsManager()
    
    @Published var currentTip: SmartTip?
    @Published var hasSeenTips: Set<String> = []
    
    private let tipsKey = "com.areabook.seenTips"
    
    private init() {
        loadSeenTips()
    }
    
    private func loadSeenTips() {
        if let data = UserDefaults.standard.data(forKey: tipsKey),
           let tips = try? JSONDecoder().decode(Set<String>.self, from: data) {
            hasSeenTips = tips
        }
    }
    
    private func saveSeenTips() {
        if let data = try? JSONEncoder().encode(hasSeenTips) {
            UserDefaults.standard.set(data, forKey: tipsKey)
        }
    }
    
    func showTipIfNeeded(_ tip: SmartTip) {
        guard !hasSeenTips.contains(tip.id) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                self.currentTip = tip
            }
        }
    }
    
    func markTipAsSeen(_ tip: SmartTip) {
        hasSeenTips.insert(tip.id)
        saveSeenTips()
        
        withAnimation(.spring()) {
            if currentTip?.id == tip.id {
                currentTip = nil
            }
        }
    }
    
    func resetAllTips() {
        hasSeenTips.removeAll()
        saveSeenTips()
    }
}

// MARK: - Smart Tip Model
struct SmartTip: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let icon: String
    let color: Color
    let placement: TipPlacement
    
    enum TipPlacement {
        case top
        case center
        case bottom
    }
}

// MARK: - Predefined Tips
extension SmartTip {
    static let dashboardPullToRefresh = SmartTip(
        id: "dashboard.pullToRefresh",
        title: "Pull to Refresh",
        message: "Swipe down to refresh your dashboard data anytime",
        icon: "arrow.down.circle",
        color: .blue,
        placement: .top
    )
    
    static let firstKeyIndicator = SmartTip(
        id: "keyIndicator.first",
        title: "Track Your Progress",
        message: "Create your first life tracker to monitor weekly habits",
        icon: "chart.bar.fill",
        color: .green,
        placement: .center
    )
    
    static let quickUpdate = SmartTip(
        id: "keyIndicator.quickUpdate",
        title: "Quick Updates",
        message: "Tap +1 or +5 buttons for fast progress updates",
        icon: "hand.tap.fill",
        color: .orange,
        placement: .bottom
    )
    
    static let taskSwipe = SmartTip(
        id: "task.swipe",
        title: "Swipe Actions",
        message: "Swipe left on tasks to delete or edit them quickly",
        icon: "hand.draw.fill",
        color: .purple,
        placement: .center
    )
    
    static let floatingButton = SmartTip(
        id: "fab.quickActions",
        title: "Quick Actions",
        message: "Tap the + button to quickly create items or update progress",
        icon: "plus.circle.fill",
        color: .blue,
        placement: .bottom
    )
    
    static let goalStickyNotes = SmartTip(
        id: "goal.stickyNotes",
        title: "Brainstorm Ideas",
        message: "Add sticky notes to your goals for planning and ideas",
        icon: "note.text",
        color: .yellow,
        placement: .center
    )
    
    static let recurringEvents = SmartTip(
        id: "calendar.recurring",
        title: "Recurring Events",
        message: "Set up repeating events for regular activities",
        icon: "repeat",
        color: .teal,
        placement: .top
    )
}

// MARK: - Smart Tip View
struct SmartTipView: View {
    let tip: SmartTip
    let onDismiss: () -> Void
    let onLearnMore: (() -> Void)?
    
    @State private var isAnimating = false
    
    init(tip: SmartTip, onDismiss: @escaping () -> Void, onLearnMore: (() -> Void)? = nil) {
        self.tip = tip
        self.onDismiss = onDismiss
        self.onLearnMore = onLearnMore
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Circle()
                    .fill(tip.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: tip.icon)
                            .font(.title3)
                            .foregroundColor(tip.color)
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(tip.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(tip.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            
            HStack {
                if let onLearnMore = onLearnMore {
                    Button("Learn More") {
                        onLearnMore()
                    }
                    .font(.caption)
                    .foregroundColor(tip.color)
                    
                    Spacer()
                }
                
                Button("Got it!") {
                    onDismiss()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(tip.color)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Smart Tip Overlay Modifier
struct SmartTipOverlay: ViewModifier {
    @ObservedObject var tipsManager = SmartTipsManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                if let tip = tipsManager.currentTip {
                    SmartTipView(tip: tip) {
                        tipsManager.markTipAsSeen(tip)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
    }
    
    private var alignment: Alignment {
        switch tipsManager.currentTip?.placement {
        case .top:
            return .top
        case .center:
            return .center
        case .bottom, .none:
            return .bottom
        }
    }
}

// MARK: - Contextual Help Button
struct ContextualHelpButton: View {
    let topic: HelpTopic
    @State private var showingHelp = false
    
    enum HelpTopic {
        case keyIndicators
        case goals
        case tasks
        case calendar
        case groups
        
        var title: String {
            switch self {
            case .keyIndicators: return "About Life Trackers"
            case .goals: return "About Goals"
            case .tasks: return "About Tasks"
            case .calendar: return "About Calendar"
            case .groups: return "About Groups"
            }
        }
        
        var content: String {
            switch self {
            case .keyIndicators:
                return "Life Trackers help you monitor weekly habits and activities. Set targets and track your progress throughout the week."
            case .goals:
                return "Goals are your long-term objectives. Link them to Life Trackers and use sticky notes to plan your path to success."
            case .tasks:
                return "Tasks are actionable items that help you achieve your goals. Set priorities, due dates, and break them down with subtasks."
            case .calendar:
                return "Schedule events and plan your time. Create recurring events for regular activities and link them to your goals."
            case .groups:
                return "Share progress with accountability partners. Create groups, invite friends, and motivate each other."
            }
        }
    }
    
    var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .popover(isPresented: $showingHelp) {
            VStack(alignment: .leading, spacing: 12) {
                Text(topic.title)
                    .font(.headline)
                
                Text(topic.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Got it") {
                    showingHelp = false
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: 300)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - View Extension
extension View {
    func smartTips() -> some View {
        modifier(SmartTipOverlay())
    }
    
    func showSmartTipOnAppear(_ tip: SmartTip) -> some View {
        onAppear {
            SmartTipsManager.shared.showTipIfNeeded(tip)
        }
    }
}