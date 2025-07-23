import SwiftUI

struct AcademicView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showingAddAssignment = false
    @State private var showingStudyTimer = false
    @State private var showingGradeEntry = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Academic Tab", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Assignments").tag(1)
                    Text("Study Timer").tag(2)
                    Text("Grades").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    AcademicOverviewView()
                        .tag(0)
                    
                    AssignmentsView()
                        .tag(1)
                    
                    StudyTimerView()
                        .tag(2)
                    
                    GradesView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Academic")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Quick add assignment
                        showingAddAssignment = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
        }
            .sheet(isPresented: $showingAddAssignment) {
                AddAssignmentView()
            }
        }
    }
}

// MARK: - Academic Overview
struct AcademicOverviewView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var currentGPA: Double = 3.75
    @State private var upcomingAssignments: [AcademicAssignment] = []
    @State private var studyStreak: Int = 5
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // GPA Card
                VStack(spacing: 16) {
                    HStack {
                        Text("Current GPA")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.2f", currentGPA))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
    }
    
                    // GPA Progress Ring
            ZStack {
                Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                
                Circle()
                            .trim(from: 0, to: gpaProgress)
                            .stroke(gpaColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: gpaProgress)
                
                        VStack {
                            Text("\(Int(gpaProgress * 100))")
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
                
                // Study Streak
                VStack(alignment: .leading, spacing: 12) {
                    Text("Study Streak")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
            HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        Text("\(studyStreak) days")
                            .font(.title2)
                            .fontWeight(.bold)
                
                Spacer()
                
                        Text("Keep it up!")
                            .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
                
                // Upcoming Assignments
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming Assignments")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if upcomingAssignments.isEmpty {
                        Text("No upcoming assignments")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(upcomingAssignments.prefix(3)) { assignment in
                            AssignmentRow(assignment: assignment)
                }
            }
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
                            title: "Study Timer",
                            icon: "timer",
                            color: .purple
                        ) {
                            // Open study timer
                        }
                        
                        QuickActionCard(
                            title: "Add Assignment",
                            icon: "plus.circle",
                            color: .blue
                        ) {
                            // Add assignment
                        }
                        
                        QuickActionCard(
                            title: "Enter Grade",
                            icon: "chart.bar",
                            color: .green
                        ) {
                            // Enter grade
                        }
                        
                        QuickActionCard(
                            title: "Study Plan",
                            icon: "calendar",
                            color: .orange
                        ) {
                            // Study plan
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

    private var gpaProgress: Double {
        return currentGPA / 4.0
    }
    
    private var gpaColor: Color {
        if currentGPA >= 3.5 { return .green }
        else if currentGPA >= 3.0 { return .blue }
        else if currentGPA >= 2.5 { return .yellow }
        else { return .red }
    }
}

// MARK: - Assignments View
struct AssignmentsView: View {
    @State private var assignments: [AcademicAssignment] = []
    @State private var selectedFilter: AssignmentFilter = .all
    @State private var showingAddAssignment = false
    
    enum AssignmentFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case completed = "Completed"
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AssignmentFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
                
                // Assignments List
            List {
                ForEach(filteredAssignments) { assignment in
                    AssignmentDetailRow(assignment: assignment)
            }
                .onDelete(perform: deleteAssignment)
        }
    }
        .navigationTitle("Assignments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddAssignment = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAssignment) {
            AddAssignmentView()
        }
    }
    
    private var filteredAssignments: [AcademicAssignment] {
        switch selectedFilter {
        case .all:
            return assignments
        case .upcoming:
            return assignments.filter { $0.dueDate > Date() && !$0.isCompleted }
        case .overdue:
            return assignments.filter { $0.dueDate < Date() && !$0.isCompleted }
        case .completed:
            return assignments.filter { $0.isCompleted }
        }
    }
    
    private func deleteAssignment(offsets: IndexSet) {
        assignments.remove(atOffsets: offsets)
    }
}

// MARK: - Study Timer View
struct StudyTimerView: View {
    @State private var selectedDuration: Int = 25
    @State private var isTimerRunning = false
    @State private var remainingTime: Int = 1500 // 25 minutes in seconds
    @State private var timer: Timer?
    @State private var studySession: StudySession?
    @State private var showingSessionComplete = false
    
    let durations = [15, 25, 45, 60, 90]
    
    var body: some View {
        VStack(spacing: 30) {
            // Timer Display
            VStack(spacing: 16) {
                Text(timeString)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundColor(isTimerRunning ? .blue : .primary)
                
                if isTimerRunning {
                    Text("Study session in progress...")
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
                    Text("Select Study Duration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
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

            // Study Session Info
            if let session = studySession {
                VStack(spacing: 12) {
                    Text("Today's Study Time")
                .font(.headline)
                .fontWeight(.semibold)
            
                    Text("\(session.totalMinutes) minutes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                }
                    
                    Spacer()
        }
        .padding()
        .onDisappear {
            stopTimer()
                }
        .sheet(isPresented: $showingSessionComplete) {
            StudySessionCompleteView(session: studySession!)
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
        studySession = StudySession(startTime: Date(), duration: selectedDuration)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimer()
                showingSessionComplete = true
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

// MARK: - Grades View
struct GradesView: View {
    @State private var courses: [Course] = []
    @State private var showingAddGrade = false
    @State private var selectedCourse: Course?
    
    var body: some View {
        VStack(spacing: 0) {
            // GPA Summary
            VStack(spacing: 16) {
                Text("Current GPA")
                .font(.headline)
                .fontWeight(.semibold)
            
                Text(String(format: "%.2f", calculateGPA()))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
        }
        .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding()
            
            // Courses List
            List {
                ForEach(courses) { course in
                    CourseGradeRow(course: course) {
                        selectedCourse = course
                        showingAddGrade = true
                    }
                }
            }
        }
        .navigationTitle("Grades")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddGrade = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGrade) {
            AddGradeView(course: selectedCourse)
        }
    }
    
    private func calculateGPA() -> Double {
        guard !courses.isEmpty else { return 0.0 }
        let totalPoints = courses.reduce(0.0) { $0 + $1.gradePoints }
        let totalCredits = courses.reduce(0.0) { $0 + $1.credits }
        return totalCredits > 0 ? totalPoints / totalCredits : 0.0
            }
        }

// MARK: - Supporting Views and Models
struct AcademicAssignment: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var course: String
    var dueDate: Date
    var priority: AssignmentPriority
    var isCompleted: Bool
    var grade: Double?
    var notes: String
    
    enum AssignmentPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

struct StudySession: Identifiable, Codable {
    let id = UUID()
    let startTime: Date
    let duration: Int // in minutes
    let endTime: Date
    
    var totalMinutes: Int {
        return duration
    }
    
    init(startTime: Date, duration: Int) {
        self.startTime = startTime
        self.duration = duration
        self.endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
    }
}

struct Course: Identifiable, Codable {
    let id = UUID()
    var name: String
    var code: String
    var credits: Double
    var grade: Double
    var assignments: [AcademicAssignment]
    
    var gradePoints: Double {
        return grade * credits
    }
    
    var letterGrade: String {
        switch grade {
        case 4.0: return "A"
        case 3.7: return "A-"
        case 3.3: return "B+"
        case 3.0: return "B"
        case 2.7: return "B-"
        case 2.3: return "C+"
        case 2.0: return "C"
        case 1.7: return "C-"
        case 1.3: return "D+"
        case 1.0: return "D"
        default: return "F"
        }
    }
}

struct AssignmentRow: View {
    let assignment: AcademicAssignment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(assignment.course)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(assignment.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(assignment.priority.color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AssignmentDetailRow: View {
    let assignment: AcademicAssignment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(assignment.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if assignment.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
            }
        }
            
            Text(assignment.course)
                    .font(.subheadline)
                .foregroundColor(.secondary)
                
            if !assignment.description.isEmpty {
                Text(assignment.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(assignment.dueDate, style: .date, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            
            Spacer()
            
                Text(assignment.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(assignment.priority.color.opacity(0.2))
                    .foregroundColor(assignment.priority.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CourseGradeRow: View {
    let course: Course
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
        HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(course.code)
                .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            
            Spacer()
            
                VStack(alignment: .trailing, spacing: 4) {
                    Text(course.letterGrade)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                
                    Text(String(format: "%.1f", course.grade))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var course = ""
    @State private var dueDate = Date()
    @State private var priority = AcademicAssignment.AssignmentPriority.medium
    
    var body: some View {
        NavigationView {
            Form {
                Section("Assignment Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Course", text: $course)
                }
                
                Section("Due Date & Priority") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(AcademicAssignment.AssignmentPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }
            }
            .navigationTitle("Add Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save assignment
                        dismiss()
                    }
                    .disabled(title.isEmpty || course.isEmpty)
                }
            }
        }
    }
}

struct AddGradeView: View {
    @Environment(\.dismiss) private var dismiss
    let course: Course?
    @State private var selectedCourse = ""
    @State private var grade = 4.0
    @State private var assignmentName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Grade Details") {
                    TextField("Assignment Name", text: $assignmentName)
                    
                    Picker("Course", selection: $selectedCourse) {
                        Text("Select Course").tag("")
                        // Add course options
                    }
                    
                    HStack {
                        Text("Grade")
            Spacer()
                        Text(String(format: "%.1f", grade))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Slider(value: $grade, in: 0...4, step: 0.1)
                }
            }
            .navigationTitle("Add Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save grade
                        dismiss()
                    }
                    .disabled(assignmentName.isEmpty || selectedCourse.isEmpty)
                }
            }
        }
    }
}

struct StudySessionCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    let session: StudySession
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            
                Text("Study Session Complete!")
                    .font(.title)
                .fontWeight(.bold)
                
                VStack(spacing: 8) {
                    Text("Duration: \(session.duration) minutes")
                        .font(.headline)
            
                    Text("Great job staying focused!")
                        .font(.subheadline)
                .foregroundColor(.secondary)
        }
                
                Button("Continue") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
    }
            .padding()
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