import SwiftUI

struct FitnessView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showingAddWorkout = false
    @State private var showingNutritionEntry = false
    @State private var showingHealthMetrics = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Fitness Tab", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Workouts").tag(1)
                    Text("Nutrition").tag(2)
                    Text("Health").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    FitnessOverviewView()
                        .tag(0)
                    
                    WorkoutsView()
                        .tag(1)
                    
                    NutritionView()
                        .tag(2)
                    
                    HealthView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Fitness")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Quick add workout
                        showingAddWorkout = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
        }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView()
            }
        }
    }
}

// MARK: - Fitness Overview
struct FitnessOverviewView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var weeklyWorkouts: Int = 4
    @State private var weeklyCalories: Int = 1850
    @State private var weeklySteps: Int = 45000
    @State private var currentWeight: Double = 70.5
    @State private var targetWeight: Double = 68.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weekly Stats
                VStack(spacing: 16) {
                    Text("This Week")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        StatCard(
                            title: "Workouts",
                            value: "\(weeklyWorkouts)",
                            icon: "dumbbell",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Calories",
                            value: "\(weeklyCalories)",
                            icon: "flame",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Steps",
                            value: "\(weeklySteps/1000)k",
                            icon: "figure.walk",
                            color: .green
                        )
                }
            }
            .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Weight Progress
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weight Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f kg", currentWeight))
                                .font(.title2)
                        .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            Text(String(format: "%.1f kg", targetWeight))
                                .font(.title2)
                                .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
                    }
                    
                    ProgressView(value: weightProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("\(Int((currentWeight - targetWeight) * 100))% to goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
        }
        .padding()
                .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
                
                // Recent Workouts
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .fontWeight(.semibold)
            
                    ForEach(recentWorkouts) { workout in
                        WorkoutRow(workout: workout)
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
                            title: "Start Workout",
                            icon: "play.circle",
                            color: .green
                        ) {
                            // Start workout
                        }
                        
                        QuickActionCard(
                            title: "Log Nutrition",
                            icon: "plus.circle",
                            color: .orange
                        ) {
                            // Log nutrition
                        }
                        
                        QuickActionCard(
                            title: "Health Metrics",
                            icon: "heart",
                            color: .red
                        ) {
                            // Health metrics
                        }
                        
                        QuickActionCard(
                            title: "Progress Photos",
                            icon: "camera",
                            color: .purple
                        ) {
                            // Progress photos
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
    
    private var weightProgress: Double {
        let total = abs(currentWeight - targetWeight)
        let remaining = abs(currentWeight - targetWeight)
        return total > 0 ? (total - remaining) / total : 0
    }
    
    private var recentWorkouts: [Workout] {
        // Mock data - replace with real data
        return [
            Workout(name: "Upper Body", duration: 45, calories: 320, date: Date().addingTimeInterval(-86400)),
            Workout(name: "Cardio", duration: 30, calories: 280, date: Date().addingTimeInterval(-172800)),
            Workout(name: "Lower Body", duration: 50, calories: 350, date: Date().addingTimeInterval(-259200))
        ]
    }
}

// MARK: - Workouts View
struct WorkoutsView: View {
    @State private var workouts: [Workout] = []
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var showingAddWorkout = false
    
    enum WorkoutFilter: String, CaseIterable {
        case all = "All"
        case strength = "Strength"
        case cardio = "Cardio"
        case yoga = "Yoga"
        case other = "Other"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Workouts List
            List {
                ForEach(filteredWorkouts) { workout in
                    WorkoutDetailRow(workout: workout)
                }
                .onDelete(perform: deleteWorkout)
            }
        }
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddWorkout = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutView()
        }
    }
    
    private var filteredWorkouts: [Workout] {
        switch selectedFilter {
        case .all:
            return workouts
        case .strength:
            return workouts.filter { $0.type == .strength }
        case .cardio:
            return workouts.filter { $0.type == .cardio }
        case .yoga:
            return workouts.filter { $0.type == .yoga }
        case .other:
            return workouts.filter { $0.type == .other }
            }
        }
    
    private func deleteWorkout(offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
    }
}

// MARK: - Nutrition View
struct NutritionView: View {
    @State private var dailyNutrition: DailyNutrition = DailyNutrition()
    @State private var showingAddFood = false
    @State private var selectedMeal: Meal = .breakfast
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily Summary
                VStack(spacing: 16) {
                    Text("Today's Nutrition")
                .font(.headline)
                .fontWeight(.semibold)
            
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        NutritionCard(
                            title: "Calories",
                            value: "\(dailyNutrition.totalCalories)",
                            target: "2000",
                            unit: "kcal",
                            color: .orange
                )
                
                        NutritionCard(
                            title: "Protein",
                            value: "\(dailyNutrition.protein)",
                            target: "150",
                    unit: "g",
                    color: .blue
                )
                
                        NutritionCard(
                            title: "Carbs",
                            value: "\(dailyNutrition.carbs)",
                            target: "250",
                    unit: "g",
                            color: .green
                        )
                        
                        NutritionCard(
                            title: "Fat",
                            value: "\(dailyNutrition.fat)",
                            target: "65",
                            unit: "g",
                            color: .purple
                )
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Meals
        VStack(alignment: .leading, spacing: 12) {
                    Text("Meals")
                .font(.headline)
                .fontWeight(.semibold)
            
                    ForEach(Meal.allCases, id: \.self) { meal in
                        MealRow(meal: meal, nutrition: dailyNutrition.mealNutrition[meal] ?? [])
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Water Intake
        VStack(alignment: .leading, spacing: 12) {
            Text("Water Intake")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                            Text("\(dailyNutrition.waterIntake) / 8 glasses")
                                .font(.title2)
                        .fontWeight(.bold)
                            Text("Daily Goal")
                                .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                        Button(action: addWater) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    ProgressView(value: Double(dailyNutrition.waterIntake) / 8.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
        }
        .padding()
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddFood = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodView(selectedMeal: selectedMeal)
                }
    }
    
    private func addWater() {
        dailyNutrition.waterIntake = min(dailyNutrition.waterIntake + 1, 8)
    }
}

// MARK: - Health View
struct HealthView: View {
    @State private var healthMetrics: HealthMetrics = HealthMetrics()
    @State private var showingAddMetric = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Vital Signs
                VStack(spacing: 16) {
                    Text("Vital Signs")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        HealthMetricCard(
                            title: "Heart Rate",
                            value: "\(healthMetrics.heartRate)",
                            unit: "bpm",
                            color: .red,
                            isNormal: healthMetrics.heartRate >= 60 && healthMetrics.heartRate <= 100
                        )
                        
                        HealthMetricCard(
                            title: "Blood Pressure",
                            value: "\(healthMetrics.systolic)/\(healthMetrics.diastolic)",
                            unit: "mmHg",
                            color: .orange,
                            isNormal: healthMetrics.systolic < 140 && healthMetrics.diastolic < 90
                        )
                        
                        HealthMetricCard(
                            title: "Weight",
                            value: String(format: "%.1f", healthMetrics.weight),
                            unit: "kg",
                            color: .blue,
                            isNormal: true
                        )
                        
                        HealthMetricCard(
                            title: "Body Fat",
                            value: String(format: "%.1f", healthMetrics.bodyFat),
                            unit: "%",
                            color: .purple,
                            isNormal: healthMetrics.bodyFat >= 10 && healthMetrics.bodyFat <= 25
                        )
                }
            }
            .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Sleep Tracking
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sleep")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f hours", healthMetrics.sleepHours))
                        .font(.title2)
                        .fontWeight(.bold)
                            Text("Last Night")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Quality")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(healthMetrics.sleepQuality.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(healthMetrics.sleepQuality.color)
                        }
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
        .cornerRadius(16)

                // Health Goals
        VStack(alignment: .leading, spacing: 12) {
                    Text("Health Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
                    ForEach(healthMetrics.goals) { goal in
                        HealthGoalRow(goal: goal)
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
            .padding()
    }
        .navigationTitle("Health")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddMetric = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMetric) {
            AddHealthMetricView()
        }
    }
}

// MARK: - Supporting Views and Models
struct Workout: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: WorkoutType
    var duration: Int // in minutes
    var calories: Int
    var date: Date
    var exercises: [Exercise]
    var notes: String
    
    enum WorkoutType: String, Codable, CaseIterable {
        case strength = "Strength"
        case cardio = "Cardio"
        case yoga = "Yoga"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .strength: return "dumbbell"
            case .cardio: return "heart"
            case .yoga: return "figure.mind.and.body"
            case .other: return "figure.mixed.cardio"
            }
        }
        
        var color: Color {
            switch self {
            case .strength: return .blue
            case .cardio: return .red
            case .yoga: return .purple
            case .other: return .gray
            }
        }
    }
}

struct Exercise: Identifiable, Codable {
    let id = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double? // in kg
    var duration: Int? // in seconds
    var notes: String
}

struct DailyNutrition: Codable {
    var totalCalories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var waterIntake: Int = 0
    var mealNutrition: [Meal: [FoodItem]] = [:]
}

struct FoodItem: Identifiable, Codable {
    let id = UUID()
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String
    var meal: Meal
}

enum Meal: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snacks: return "leaf"
        }
    }
}

struct HealthMetrics: Codable {
    var heartRate: Int = 72
    var systolic: Int = 120
    var diastolic: Int = 80
    var weight: Double = 70.5
    var bodyFat: Double = 15.0
    var sleepHours: Double = 7.5
    var sleepQuality: SleepQuality = .good
    var goals: [HealthGoal] = []
}

enum SleepQuality: String, Codable, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
    
    var color: Color {
        switch self {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }
}

struct HealthGoal: Identifiable, Codable {
    let id = UUID()
    var title: String
    var target: Double
    var current: Double
    var unit: String
    var isCompleted: Bool
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct NutritionCard: View {
    let title: String
    let value: String
    let target: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("of \(target) \(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var progress: Double {
        guard let value = Double(value), let target = Double(target) else { return 0 }
        return target > 0 ? min(value / target, 1.0) : 0
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let isNormal: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isNormal ? color : .red)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Circle()
                .fill(isNormal ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
            }
        }

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.duration) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(workout.calories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WorkoutDetailRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(workout.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(workout.type.color.opacity(0.2))
                    .foregroundColor(workout.type.color)
                    .cornerRadius(8)
            }
            
            HStack {
                Label("\(workout.duration) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(workout.calories) cal", systemImage: "flame")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(workout.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MealRow: View {
    let meal: Meal
    let nutrition: [FoodItem]
    
    var body: some View {
        HStack {
            Image(systemName: meal.icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if nutrition.isEmpty {
                    Text("No foods logged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(nutrition.count) items • \(nutrition.reduce(0) { $0 + $1.calories }) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct HealthGoalRow: View {
    let goal: HealthGoal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(goal.current)) / \(Int(goal.target)) \(goal.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if goal.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView(value: goal.current / goal.target)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type = Workout.WorkoutType.strength
    @State private var duration = 30
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    TextField("Workout Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(Workout.WorkoutType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Stepper("Duration: \(duration) minutes", value: $duration, in: 5...180, step: 5)
            }
            
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
        }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save workout
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedMeal: Meal
    @State private var name = ""
    @State private var calories = 0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0
    @State private var servingSize = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $name)
                    TextField("Serving Size", text: $servingSize)
                }
                
                Section("Nutrition") {
        HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", value: $calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", value: $protein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
            }
            
                    HStack {
                        Text("Carbs (g)")
            Spacer()
                        TextField("0", value: $carbs, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", value: $fat, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save food
                        dismiss()
        }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddHealthMetricView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric = "Heart Rate"
    @State private var value = ""
    
    let metrics = ["Heart Rate", "Blood Pressure", "Weight", "Body Fat", "Sleep Hours"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Metric Details") {
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(metrics, id: \.self) { metric in
                            Text(metric).tag(metric)
                        }
                    }
                    
                    TextField("Value", text: $value)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save metric
                        dismiss()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
    }
} 