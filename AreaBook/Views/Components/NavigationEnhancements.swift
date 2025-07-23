import SwiftUI

// MARK: - Enhanced Navigation Components
struct SmoothNavigationLink<Destination: View, Label: View>: View {
    let destination: Destination
    let label: Label
    @State private var isActive = false
    
    init(destination: Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }
    
    var body: some View {
        NavigationLink(destination: destination, isActive: $isActive) {
            label
        }
        .buttonStyle(SmoothNavigationButtonStyle())
    }
}

struct SmoothNavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Transitions
struct SlideTransition: ViewModifier {
    let edge: Edge
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: .move(edge: edge).combined(with: .opacity),
                removal: .move(edge: edge).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

struct FadeTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

struct ScaleTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.scale(scale: isActive ? 1.0 : 0.8).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Enhanced Tab Bar
struct EnhancedTabBar: View {
    let tabs: [TabItem]
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                EnhancedTabItem(
                    tab: tabs[index],
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                    HapticManager.shared.tabSwitched()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2) // Reduced radius from 10 to 3 for better performance
        )
        .padding(.horizontal, 20)
    }
}

struct TabItem {
    let icon: String
    let selectedIcon: String
    let title: String
    let color: Color
}

struct EnhancedTabItem: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? tab.color : .gray)
                
                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? tab.color : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Floating Action Button with Animation
struct AnimatedFloatingButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonPressed()
            action()
        }) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
                )
        }
        .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Pull to Refresh Enhancement
struct EnhancedPullToRefresh: ViewModifier {
    let action: @escaping () async -> Void
    @State private var isRefreshing = false
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                HapticManager.shared.refreshStarted()
                isRefreshing = true
                await action()
                isRefreshing = false
                HapticManager.shared.refreshCompleted()
            }
            .overlay(
                Group {
                    if isRefreshing {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("Refreshing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRefreshing)
            )
    }
}

// MARK: - Search Enhancement
struct EnhancedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: () -> Void
    
    @State private var isSearching = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .onSubmit {
                        HapticManager.shared.searchCompleted()
                        onSearch()
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        HapticManager.shared.lightImpact()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
            )
            
            if isFocused {
                Button("Cancel") {
                    isFocused = false
                    text = ""
                    HapticManager.shared.lightImpact()
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        .onChange(of: isFocused) { focused in
            if focused {
                HapticManager.shared.searchStarted()
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func slideTransition(edge: Edge = .trailing, isActive: Bool) -> some View {
        modifier(SlideTransition(edge: edge, isActive: isActive))
    }
    
    func fadeTransition(isActive: Bool) -> some View {
        modifier(FadeTransition(isActive: isActive))
    }
    
    func scaleTransition(isActive: Bool) -> some View {
        modifier(ScaleTransition(isActive: isActive))
    }
    
    func enhancedPullToRefresh(action: @escaping () async -> Void) -> some View {
        modifier(EnhancedPullToRefresh(action: action))
    }
} 