import SwiftUI

struct WellnessView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showingMoodEntry = false
    @State private var showingMeditationTimer = false
    @State private var showingSelfCareRoutine = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Wellness Tab", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Mood").tag(1)
                    Text("Meditation").tag(2)
                    Text("Self-Care").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    WellnessOverviewView()
                        .tag(0)
                    
                    MoodTrackingView()
                        .tag(1)
                    
                    MeditationView()
                        .tag(2)
                    
                    SelfCareView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Wellness")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Quick mood entry
                            showingMoodEntry = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingMoodEntry) {
                QuickMoodEntryView()
            }
        }
    }
}

// MARK: - Wellness Overview
struct WellnessOverviewView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var currentMood: MoodType = .good
    @State private var weeklyMoodData: [MoodEntry] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Mood Card
                VStack(spacing: 16) {
                    HStack {
                        Text("Today's Mood")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(currentMood.emoji)
                            .font(.title)
                    }
                    
                    Text(currentMood.displayName)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // Mood Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: moodProgress)
                            .stroke(moodColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: moodProgress)
                        
                        VStack {
                            Text("\(Int(moodProgress * 100))")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("%")
                            .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Weekly Mood Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Mood")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    WeeklyMoodChart(data: weeklyMoodData)
                    }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        QuickActionCard(
                            title: "Meditation",
                            icon: "timer",
                            color: .purple
                        ) {
                            // Open meditation timer
                        }
                        
                        QuickActionCard(
                            title: "Self-Care",
                            icon: "leaf",
                            color: .green
                        ) {
                            // Open self-care routine
                        }
                        
                        QuickActionCard(
                            title: "Mood Entry",
                            icon: "heart",
                            color: .pink
                        ) {
                            // Open mood entry
                        }
                        
                        QuickActionCard(
                            title: "Journal",
                            icon: "book",
                            color: .orange
                        ) {
                            // Open journal
                        }
            }
        }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    private var moodProgress: Double {
        switch currentMood {
        case .excellent: return 1.0
        case .good: return 0.8
        case .okay: return 0.6
        case .bad: return 0.4
        case .terrible: return 0.2
        }
    }
    
    private var moodColor: Color {
        switch currentMood {
        case .excellent: return .green
        case .good: return .blue
        case .okay: return .yellow
        case .bad: return .orange
        case .terrible: return .red
        }
    }
}

// MARK: - Mood Tracking View
struct MoodTrackingView: View {
    @State private var selectedMood: MoodType = .good
    @State private var moodNotes = ""
    @State private var showingMoodHistory = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mood Selection
                VStack(spacing: 16) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            MoodSelectionCard(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                onTap: { selectedMood = mood }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes (Optional)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("How was your day?", text: $moodNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Save Button
                Button(action: saveMoodEntry) {
                    Text("Save Mood Entry")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Mood History
                Button(action: { showingMoodHistory = true }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("View Mood History")
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingMoodHistory) {
            MoodHistoryView()
    }
}

    private func saveMoodEntry() {
        let entry = MoodEntry(
            mood: selectedMood,
            notes: moodNotes,
            timestamp: Date()
        )
        // Save to data manager
        print("Saving mood entry: \(entry)")
    }
}

// MARK: - Meditation View
struct MeditationView: View {
    @State private var selectedDuration: Int = 10
    @State private var isTimerRunning = false
    @State private var remainingTime: Int = 600 // 10 minutes in seconds
    @State private var timer: Timer?
    
    let durations = [5, 10, 15, 20, 30, 45, 60]
    
    var body: some View {
        VStack(spacing: 30) {
            // Timer Display
            VStack(spacing: 16) {
                Text(timeString)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundColor(isTimerRunning ? .blue : .primary)
                
                if isTimerRunning {
                    Text("Meditation in progress...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            
            // Duration Selection
            if !isTimerRunning {
        VStack(spacing: 16) {
                    Text("Select Duration")
                .font(.headline)
                .fontWeight(.semibold)
            
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(durations, id: \.self) { duration in
                            Button(action: { selectedDuration = duration }) {
                                Text("\(duration)m")
                                    .font(.headline)
                                    .foregroundColor(selectedDuration == duration ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedDuration == duration ? Color.blue : Color(.tertiarySystemBackground))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
            
            // Control Buttons
            HStack(spacing: 20) {
                if isTimerRunning {
                    Button(action: pauseTimer) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: stopTimer) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: startTimer) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onDisappear {
            stopTimer()
        }
    }
    
    private var timeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        remainingTime = selectedDuration * 60
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimer()
                // Show completion alert
            }
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        remainingTime = selectedDuration * 60
    }
}

// MARK: - Self Care View
struct SelfCareView: View {
    @State private var selectedRoutine: SelfCareRoutine?
    @State private var showingRoutineDetail = false
    
    let routines = [
        SelfCareRoutine(name: "Morning Routine", activities: ["Hydration", "Stretching", "Gratitude"], duration: 15),
        SelfCareRoutine(name: "Stress Relief", activities: ["Deep Breathing", "Progressive Relaxation", "Mindful Walking"], duration: 20),
        SelfCareRoutine(name: "Evening Wind Down", activities: ["Tea Time", "Reading", "Reflection"], duration: 30),
        SelfCareRoutine(name: "Weekend Reset", activities: ["Nature Walk", "Creative Activity", "Social Connection"], duration: 60)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(routines, id: \.name) { routine in
                    SelfCareRoutineCard(routine: routine) {
                        selectedRoutine = routine
                        showingRoutineDetail = true
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingRoutineDetail) {
            if let routine = selectedRoutine {
                SelfCareRoutineDetailView(routine: routine)
            }
        }
    }
}

// MARK: - Supporting Views and Models
struct MoodEntry: Identifiable, Codable {
    let id = UUID()
    let mood: MoodType
    let notes: String
    let timestamp: Date
}

struct SelfCareRoutine: Identifiable {
    let id = UUID()
    let name: String
    let activities: [String]
    let duration: Int // in minutes
}

struct MoodSelectionCard: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.title)
                    
                Text(mood.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeeklyMoodChart: View {
    let data: [MoodEntry]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<7) { day in
                VStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 30, height: CGFloat.random(in: 20...100))
                        .cornerRadius(4)
            
                    Text(dayLabel(for: day))
                        .font(.caption2)
                .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[index]
            }
        }

struct SelfCareRoutineCard: View {
    let routine: SelfCareRoutine
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
        VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(routine.name)
                .font(.headline)
                .fontWeight(.semibold)
                    Spacer()
                    Text("\(routine.duration)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
    }
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(routine.activities, id: \.self) { activity in
                    HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.blue)
                            Text(activity)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                }
            }
        }
        .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelfCareRoutineDetailView: View {
    let routine: SelfCareRoutine
    @State private var currentActivityIndex = 0
    @State private var isRoutineActive = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isRoutineActive {
                    // Active routine view
            VStack(spacing: 20) {
                        Text(routine.activities[currentActivityIndex])
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Activity \(currentActivityIndex + 1) of \(routine.activities.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                
                        // Progress indicator
                        ProgressView(value: Double(currentActivityIndex), total: Double(routine.activities.count - 1))
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            Button("Previous") {
                                if currentActivityIndex > 0 {
                                    currentActivityIndex -= 1
    }
}
                            .disabled(currentActivityIndex == 0)
                            
                            Button("Next") {
                                if currentActivityIndex < routine.activities.count - 1 {
                                    currentActivityIndex += 1
                                } else {
                                    // Complete routine
                                    isRoutineActive = false
                                }
                            }
                        }
                    }
                } else {
                    // Routine overview
                    VStack(spacing: 20) {
                        Text(routine.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Duration: \(routine.duration) minutes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Activities:")
                .font(.headline)
                .fontWeight(.semibold)
            
                            ForEach(routine.activities, id: \.self) { activity in
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                    Text(activity)
                .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        Button("Start Routine") {
                            isRoutineActive = true
                            currentActivityIndex = 0
                        }
                        .font(.headline)
                            .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                            .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
        }
        .padding()
            .navigationTitle(isRoutineActive ? "Active Routine" : routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
}

struct QuickMoodEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: MoodType = .good
    @State private var moodNotes = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Mood Check")
                    .font(.title2)
                .fontWeight(.semibold)
            
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(MoodType.allCases, id: \.self) { mood in
                        MoodSelectionCard(
                            mood: mood,
                            isSelected: selectedMood == mood,
                            onTap: { selectedMood = mood }
                        )
                    }
                }
                
                TextField("Quick note (optional)", text: $moodNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                
                Button("Save") {
                    // Save mood entry
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                
                Spacer()
        }
        .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MoodHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var moodHistory: [MoodEntry] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(moodHistory) { entry in
                    HStack {
                        Text(entry.mood.emoji)
                .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(entry.mood.displayName)
                                .font(.headline)
                            Text(entry.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
                        if !entry.notes.isEmpty {
                            Text(entry.notes)
                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
    }
}
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
        }
                }
            }
        }
    }
}

// MARK: - Mood Types
enum MoodType: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case okay = "Okay"
    case bad = "Bad"
    case terrible = "Terrible"
    
    var emoji: String {
        switch self {
        case .excellent: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .bad: return "😔"
        case .terrible: return "😢"
        }
    }
    
    var displayName: String {
        return rawValue
    }
}

#Preview {
    WellnessView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel.shared)
} 