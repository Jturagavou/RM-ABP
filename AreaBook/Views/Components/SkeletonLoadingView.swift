import SwiftUI

// MARK: - Skeleton Loading Components
struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header skeleton
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .frame(width: 120)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .frame(width: 80)
                }
                
                Spacer()
            }
            
            // Content skeleton
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard()
                }
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct SkeletonCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Rectangle()
                .fill(Color.gray.opacity(isAnimating ? 0.4 : 0.2))
                .frame(height: 20)
                .frame(maxWidth: .infinity)
            
            // Description
            Rectangle()
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                .frame(height: 14)
                .frame(maxWidth: .infinity)
            
            // Progress bar
            Rectangle()
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .cornerRadius(4)
            
            // Stats
            HStack {
                ForEach(0..<2, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                        .frame(height: 12)
                        .frame(width: 60)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Specific Skeleton Views
struct DashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 24)
                        .frame(width: 150)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: 100)
                }
                Spacer()
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
            }
            
            // Widget grid skeleton
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonWidget()
                }
            }
        }
        .padding()
    }
}

struct SkeletonWidget: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Widget header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(isAnimating ? 0.4 : 0.2))
                    .frame(width: 16, height: 16)
                
                Rectangle()
                    .fill(Color.gray.opacity(isAnimating ? 0.4 : 0.2))
                    .frame(height: 16)
                    .frame(width: 80)
                
                Spacer()
            }
            
            // Widget content
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .frame(height: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct GoalsSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Section headers
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 20)
                            .frame(width: 100)
                        
                        Spacer()
                    }
                    
                    // Goal cards
                    VStack(spacing: 12) {
                        ForEach(0..<2, id: \.self) { _ in
                            SkeletonGoalCard()
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct SkeletonGoalCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Goal title
            Rectangle()
                .fill(Color.gray.opacity(isAnimating ? 0.4 : 0.2))
                .frame(height: 18)
                .frame(maxWidth: .infinity)
            
            // Goal description
            Rectangle()
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                .frame(height: 14)
                .frame(maxWidth: .infinity)
            
            // Progress section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                        .frame(height: 16)
                        .frame(width: 60)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                        .frame(height: 16)
                        .frame(width: 40)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                    .frame(height: 8)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Loading State Modifier
struct LoadingStateModifier: ViewModifier {
    let isLoading: Bool
    let skeletonView: AnyView
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0 : 1)
            
            if isLoading {
                skeletonView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

extension View {
    func loadingState<Content: View>(_ isLoading: Bool, @ViewBuilder skeleton: @escaping () -> Content) -> some View {
        modifier(LoadingStateModifier(isLoading: isLoading, skeletonView: AnyView(skeleton())))
    }
} 