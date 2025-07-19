import SwiftUI

// MARK: - Help Content Views
struct HowToUseAreaBookView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Welcome to AreaBook")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AreaBook is your personal productivity companion designed to help you track and achieve your life goals. Here's how to get the most out of it:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Dashboard
                HelpSection(
                    title: "Dashboard",
                    icon: "house.fill",
                    description: "Your central hub for daily productivity. View your key indicators, today's tasks and events, and get motivated with daily quotes.",
                    tips: [
                        "Pull down to refresh your dashboard data",
                        "Tap on any card to navigate to that section",
                        "Your progress automatically syncs across all devices"
                    ]
                )
                
                // Key Indicators
                HelpSection(
                    title: "Life Trackers (Key Indicators)",
                    icon: "chart.bar.fill",
                    description: "Track important weekly habits and activities. Set targets and monitor your progress throughout the week.",
                    tips: [
                        "Use the +1 and +5 buttons for quick updates",
                        "Choose from templates or create custom trackers",
                        "Progress resets automatically each week",
                        "Color-code your trackers for easy organization"
                    ]
                )
                
                // Goals
                HelpSection(
                    title: "Goals",
                    icon: "flag.fill",
                    description: "Set and track long-term objectives. Link goals to your life trackers and add sticky notes for brainstorming.",
                    tips: [
                        "Link goals to specific life trackers",
                        "Use sticky notes to plan and organize thoughts",
                        "Set target dates to stay motivated",
                        "Update progress regularly to see your growth"
                    ]
                )
                
                // Navigation Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pro Tips")
                        .font(.headline)
                    
                    ProTip(text: "Use the floating + button to quickly create new items from any screen")
                    ProTip(text: "Swipe on tasks to mark them complete or delete them")
                    ProTip(text: "Long press on items for quick actions")
                    ProTip(text: "Use Siri Shortcuts for hands-free updates")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("How to Use AreaBook")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreatingFirstGoalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Creating Your First Goal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                StepByStep(steps: [
                    StepItem(
                        number: 1,
                        title: "Navigate to Goals",
                        description: "Tap the Goals tab at the bottom of the screen"
                    ),
                    StepItem(
                        number: 2,
                        title: "Tap Create Goal",
                        description: "Press the + button or 'Create Goal' button"
                    ),
                    StepItem(
                        number: 3,
                        title: "Fill in Details",
                        description: "Enter a meaningful title and description for your goal"
                    ),
                    StepItem(
                        number: 4,
                        title: "Link Life Trackers",
                        description: "Connect relevant life trackers to measure progress"
                    ),
                    StepItem(
                        number: 5,
                        title: "Add Sticky Notes",
                        description: "Use the sticky notes feature to brainstorm action steps"
                    ),
                    StepItem(
                        number: 6,
                        title: "Set Target Date",
                        description: "Choose a realistic deadline to achieve your goal"
                    ),
                    StepItem(
                        number: 7,
                        title: "Save and Track",
                        description: "Save your goal and update progress regularly"
                    )
                ])
                
                Text("Goal Examples")
                    .font(.headline)
                    .padding(.top)
                
                ExampleCard(
                    title: "Fitness Goal",
                    description: "Exercise 5 times per week",
                    linkedTrackers: ["Exercise Sessions", "Water Intake"],
                    notes: ["Join a gym", "Plan workout schedule", "Track progress"]
                )
                
                ExampleCard(
                    title: "Learning Goal",
                    description: "Read 12 books this year",
                    linkedTrackers: ["Reading Time", "Books Completed"],
                    notes: ["Create reading list", "Set daily reading time", "Join book club"]
                )
            }
            .padding()
        }
        .navigationTitle("Creating Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingUpKeyIndicatorsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Setting Up Life Trackers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Life Trackers (Key Indicators) help you monitor important weekly habits and activities. Here's how to set them up effectively:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Start Templates")
                        .font(.headline)
                    
                    Text("Choose from these popular templates or create your own:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        TemplateCard(name: "Exercise", unit: "sessions", color: .green)
                        TemplateCard(name: "Reading", unit: "hours", color: .blue)
                        TemplateCard(name: "Water Intake", unit: "glasses", color: .cyan)
                        TemplateCard(name: "Sleep", unit: "hours", color: .purple)
                        TemplateCard(name: "Meditation", unit: "minutes", color: .orange)
                        TemplateCard(name: "Learning", unit: "hours", color: .red)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Best Practices")
                        .font(.headline)
                    
                    BestPractice(
                        icon: "target",
                        text: "Set realistic weekly targets you can achieve"
                    )
                    BestPractice(
                        icon: "calendar",
                        text: "Update your progress daily for best results"
                    )
                    BestPractice(
                        icon: "paintbrush",
                        text: "Use colors to categorize different life areas"
                    )
                    BestPractice(
                        icon: "arrow.clockwise",
                        text: "Review and adjust targets weekly as needed"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Life Trackers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Components
struct HelpSection: View {
    let title: String
    let icon: String
    let description: String
    let tips: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(tip)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProTip: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct StepItem: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(Color.blue)
                .frame(width: 30, height: 30)
                .overlay(
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StepByStep: View {
    let steps: [StepItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                step
                if index < steps.count - 1 {
                    HStack {
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 2)
                            .padding(.leading, 14)
                        Spacer()
                    }
                    .frame(height: 20)
                }
            }
        }
    }
}

struct ExampleCard: View {
    let title: String
    let description: String
    let linkedTrackers: [String]
    let notes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                Text(linkedTrackers.joined(separator: ", "))
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                Text(notes.joined(separator: " • "))
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TemplateCard: View {
    let name: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: iconForTemplate(name))
                        .foregroundColor(color)
                )
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func iconForTemplate(_ name: String) -> String {
        switch name {
        case "Exercise": return "figure.run"
        case "Reading": return "book"
        case "Water Intake": return "drop"
        case "Sleep": return "bed.double"
        case "Meditation": return "brain.head.profile"
        case "Learning": return "graduationcap"
        default: return "star"
        }
    }
}

struct BestPractice: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}