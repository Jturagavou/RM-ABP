import SwiftUI

// MARK: - Quick Actions Menu
struct QuickActionsMenu: View {
    @Binding var isPresented: Bool
    @State private var selectedAction: QuickAction?
    @State private var animateButtons = false
    
    enum QuickAction: CaseIterable {
        case task
        case event
        case goal
        case note
        case keyIndicator
        case updateProgress
        
        var title: String {
            switch self {
            case .task: return "New Task"
            case .event: return "New Event"
            case .goal: return "New Goal"
            case .note: return "New Note"
            case .keyIndicator: return "New Tracker"
            case .updateProgress: return "Update Progress"
            }
        }
        
        var icon: String {
            switch self {
            case .task: return "checkmark.square"
            case .event: return "calendar"
            case .goal: return "flag"
            case .note: return "doc.text"
            case .keyIndicator: return "chart.bar"
            case .updateProgress: return "arrow.up.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .task: return .green
            case .event: return .blue
            case .goal: return .orange
            case .note: return .purple
            case .keyIndicator: return .red
            case .updateProgress: return .teal
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Actions grid
            VStack(spacing: 20) {
                Text("Quick Actions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(Array(QuickAction.allCases.enumerated()), id: \.offset) { index, action in
                        QuickActionButton(
                            action: action,
                            isAnimated: animateButtons,
                            delay: Double(index) * 0.05
                        ) {
                            handleAction(action)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 30)
            .scaleEffect(animateButtons ? 1 : 0.8)
            .opacity(animateButtons ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateButtons = true
            }
        }
        .sheet(item: $selectedAction) { action in
            navigationView(for: action)
        }
    }
    
    private func handleAction(_ action: QuickAction) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        withAnimation(.spring()) {
            isPresented = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedAction = action
        }
    }
    
    @ViewBuilder
    private func navigationView(for action: QuickAction) -> some View {
        switch action {
        case .task:
            CreateTaskView()
        case .event:
            CreateEventView()
        case .goal:
            CreateGoalView()
        case .note:
            CreateNoteView()
        case .keyIndicator:
            CreateKeyIndicatorView()
        case .updateProgress:
            QuickProgressUpdateView()
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let action: QuickActionsMenu.QuickAction
    let isAnimated: Bool
    let delay: Double
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(action.color.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: action.icon)
                            .font(.title2)
                            .foregroundColor(action.color)
                    )
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .scaleEffect(isAnimated ? 1 : 0)
        .opacity(isAnimated ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay), value: isAnimated)
    }
}

// MARK: - Quick Progress Update View
struct QuickProgressUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedKI: KeyIndicator?
    @State private var progressUpdates: [String: Int] = [:]
    @State private var isSaving = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Progress Update")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if dataManager.keyIndicators.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Life Trackers")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create life trackers to update progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Create Life Tracker") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(dataManager.keyIndicators) { ki in
                                QuickUpdateCard(
                                    keyIndicator: ki,
                                    currentValue: progressUpdates[ki.id] ?? ki.currentWeekProgress
                                ) { newValue in
                                    progressUpdates[ki.id] = newValue
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: saveAllUpdates) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Save All Updates")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(isSaving || progressUpdates.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .top) {
                if showSuccess {
                    SuccessToast(
                        message: "Progress updated!",
                        icon: "checkmark.circle.fill",
                        isShowing: $showSuccess
                    )
                    .padding(.top, 50)
                }
            }
        }
    }
    
    private func saveAllUpdates() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isSaving = true
        
        for (kiId, newValue) in progressUpdates {
            if let ki = dataManager.keyIndicators.first(where: { $0.id == kiId }) {
                var updatedKI = ki
                updatedKI.currentWeekProgress = newValue
                dataManager.updateKeyIndicator(updatedKI, userId: userId)
            }
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showSuccess = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Quick Update Card
struct QuickUpdateCard: View {
    let keyIndicator: KeyIndicator
    let currentValue: Int
    let onUpdate: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: keyIndicator.color) ?? .blue)
                    .frame(width: 12, height: 12)
                
                Text(keyIndicator.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(currentValue) / \(keyIndicator.weeklyTarget)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(currentValue) / Double(keyIndicator.weeklyTarget))
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: keyIndicator.color) ?? .blue))
            
            HStack(spacing: 12) {
                QuickUpdateButton(title: "+1", color: .blue) {
                    onUpdate(min(currentValue + 1, keyIndicator.weeklyTarget * 2))
                }
                
                QuickUpdateButton(title: "+5", color: .green) {
                    onUpdate(min(currentValue + 5, keyIndicator.weeklyTarget * 2))
                }
                
                QuickUpdateButton(title: "+10", color: .orange) {
                    onUpdate(min(currentValue + 10, keyIndicator.weeklyTarget * 2))
                }
                
                Spacer()
                
                if currentValue > keyIndicator.currentWeekProgress {
                    Text("+\(currentValue - keyIndicator.currentWeekProgress)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickUpdateButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(color.opacity(0.15))
                .cornerRadius(6)
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    @Binding var showingQuickActions: Bool
    @State private var isRotated = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring()) {
                showingQuickActions.toggle()
                isRotated.toggle()
            }
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                .rotationEffect(.degrees(isRotated ? 45 : 0))
                .scaleEffect(showingQuickActions ? 0.9 : 1.0)
        }
    }
}