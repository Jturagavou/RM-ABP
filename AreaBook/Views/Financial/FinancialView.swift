import SwiftUI

struct FinancialView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showingAddExpense = false
    @State private var showingAddIncome = false
    @State private var showingBudgetSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Financial Tab", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Budget").tag(1)
                    Text("Expenses").tag(2)
                    Text("Savings").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    FinancialOverviewView()
                        .tag(0)
                    
                    BudgetView()
                        .tag(1)
                    
                    ExpensesView()
                        .tag(2)
                    
                    SavingsView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Financial")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Quick add expense
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
        }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }
}

// MARK: - Financial Overview
struct FinancialOverviewView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var monthlyIncome: Double = 5000.0
    @State private var monthlyExpenses: Double = 3200.0
    @State private var monthlySavings: Double = 800.0
    @State private var currentBalance: Double = 15000.0
    @State private var savingsGoals: [SavingsGoal] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Monthly Summary
        VStack(spacing: 16) {
                    Text("This Month")
                .font(.headline)
                .fontWeight(.semibold)
            
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        FinancialCard(
                            title: "Income",
                            amount: monthlyIncome,
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )
                        
                        FinancialCard(
                            title: "Expenses",
                            amount: monthlyExpenses,
                            icon: "arrow.up.circle.fill",
                    color: .red
                )
                
                        FinancialCard(
                            title: "Savings",
                            amount: monthlySavings,
                            icon: "banknote",
                    color: .blue
                )
                
                        FinancialCard(
                            title: "Balance",
                            amount: currentBalance,
                            icon: "creditcard",
                    color: .purple
                )
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Spending Chart
        VStack(alignment: .leading, spacing: 12) {
                    Text("Spending by Category")
                .font(.headline)
                .fontWeight(.semibold)
            
                    SpendingChartView()
        }
        .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Savings Goals
        VStack(alignment: .leading, spacing: 12) {
                    Text("Savings Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
                    if savingsGoals.isEmpty {
                        Text("No savings goals set")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
        .padding()
                    } else {
                        ForEach(savingsGoals.prefix(3)) { goal in
                            SavingsGoalRow(goal: goal)
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
                            title: "Add Expense",
                            icon: "minus.circle",
                            color: .red
                        ) {
                            // Add expense
                        }
                        
                        QuickActionCard(
                            title: "Add Income",
                            icon: "plus.circle",
                            color: .green
                        ) {
                            // Add income
                        }
                        
                        QuickActionCard(
                            title: "Set Budget",
                            icon: "chart.pie",
                            color: .blue
                        ) {
                            // Set budget
                        }
                        
                        QuickActionCard(
                            title: "Savings Goal",
                            icon: "target",
                            color: .orange
                        ) {
                            // Savings goal
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
}

// MARK: - Budget View
struct BudgetView: View {
    @State private var budgetCategories: [BudgetCategory] = []
    @State private var showingAddCategory = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Budget Summary
        VStack(spacing: 16) {
                    Text("Monthly Budget")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(totalBudget, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                            Text("Spent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(totalSpent, specifier: "%.0f")")
                                .font(.title2)
                        .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                    
                    ProgressView(value: budgetProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: budgetProgress > 0.9 ? .red : .blue))
                    
                    Text("\(Int(budgetProgress * 100))% used")
                        .font(.caption)
                        .foregroundColor(.secondary)
        }
        .padding()
                .background(Color(.secondarySystemBackground))
        .cornerRadius(16)

                // Budget Categories
        VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
                        Spacer()
                        
                        Button(action: { showingAddCategory = true }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
    }
}

                    if budgetCategories.isEmpty {
                        Text("No budget categories set")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(budgetCategories) { category in
                            BudgetCategoryRow(category: category)
                    }
                }
            }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
        }
        .padding()
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCategory) {
            AddBudgetCategoryView()
        }
    }
    
    private var totalBudget: Double {
        budgetCategories.reduce(0) { $0 + $1.budget }
}

    private var totalSpent: Double {
        budgetCategories.reduce(0) { $0 + $1.spent }
    }
    
    private var budgetProgress: Double {
        totalBudget > 0 ? totalSpent / totalBudget : 0
    }
}

// MARK: - Expenses View
struct ExpensesView: View {
    @State private var expenses: [Expense] = []
    @State private var selectedFilter: ExpenseFilter = .all
    @State private var showingAddExpense = false
    
    enum ExpenseFilter: String, CaseIterable {
        case all = "All"
        case thisMonth = "This Month"
        case thisWeek = "This Week"
        case byCategory = "By Category"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ExpenseFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Expenses List
            List {
                ForEach(filteredExpenses) { expense in
                    ExpenseDetailRow(expense: expense)
        }
                .onDelete(perform: deleteExpense)
    }
}
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
    }
    
    private var filteredExpenses: [Expense] {
        switch selectedFilter {
        case .all:
            return expenses
        case .thisMonth:
            return expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .thisWeek:
            return expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        case .byCategory:
            return expenses.sorted { $0.category.rawValue < $1.category.rawValue }
                }
            }
    
    private func deleteExpense(offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        }
    }

// MARK: - Savings View
struct SavingsView: View {
    @State private var savingsGoals: [SavingsGoal] = []
    @State private var showingAddGoal = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Total Savings
        VStack(spacing: 16) {
                    Text("Total Savings")
                .font(.headline)
                .fontWeight(.semibold)
            
                    Text("$\(totalSavings, specifier: "%.2f")")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("Across all goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                    
                // Savings Goals
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Savings Goals")
                            .font(.headline)
                            .fontWeight(.semibold)
                
                Spacer()
                
                        Button(action: { showingAddGoal = true }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if savingsGoals.isEmpty {
                        Text("No savings goals set")
                            .font(.subheadline)
                        .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(savingsGoals) { goal in
                            SavingsGoalDetailRow(goal: goal)
                }
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
        .cornerRadius(16)

                // Savings Tips
        VStack(alignment: .leading, spacing: 12) {
                    Text("Savings Tips")
                .font(.headline)
                .fontWeight(.semibold)
            
                    VStack(alignment: .leading, spacing: 8) {
                        TipRow(tip: "Set up automatic transfers to savings")
                        TipRow(tip: "Follow the 50/30/20 rule")
                        TipRow(tip: "Track your expenses regularly")
                        TipRow(tip: "Set realistic savings goals")
            }
        }
        .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Savings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddGoal) {
            AddSavingsGoalView()
        }
    }
    
    private var totalSavings: Double {
        savingsGoals.reduce(0) { $0 + $1.currentAmount }
    }
}

// MARK: - Supporting Views and Models
struct Expense: Identifiable, Codable {
    let id = UUID()
    var amount: Double
    var category: ExpenseCategory
    var description: String
    var date: Date
    var isRecurring: Bool
    var recurringInterval: RecurringInterval?
    
    enum ExpenseCategory: String, Codable, CaseIterable {
        case food = "Food"
        case transportation = "Transportation"
        case housing = "Housing"
        case utilities = "Utilities"
        case entertainment = "Entertainment"
        case healthcare = "Healthcare"
        case shopping = "Shopping"
        case education = "Education"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .transportation: return "car"
            case .housing: return "house"
            case .utilities: return "bolt"
            case .entertainment: return "tv"
            case .healthcare: return "cross"
            case .shopping: return "bag"
            case .education: return "book"
            case .other: return "ellipsis.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .food: return .orange
            case .transportation: return .blue
            case .housing: return .green
            case .utilities: return .yellow
            case .entertainment: return .purple
            case .healthcare: return .red
            case .shopping: return .pink
            case .education: return .indigo
            case .other: return .gray
            }
        }
    }
    
    enum RecurringInterval: String, Codable, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
}

struct Income: Identifiable, Codable {
    let id = UUID()
    var amount: Double
    var source: String
    var date: Date
    var isRecurring: Bool
    var recurringInterval: Expense.RecurringInterval?
}

struct BudgetCategory: Identifiable, Codable {
    let id = UUID()
    var name: String
    var budget: Double
    var spent: Double
    var icon: String
    var color: String
    
    var progress: Double {
        budget > 0 ? spent / budget : 0
    }
    
    var remaining: Double {
        budget - spent
    }
}

struct SavingsGoal: Identifiable, Codable {
    let id = UUID()
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date?
    var icon: String
    var color: String
    
    var progress: Double {
        targetAmount > 0 ? currentAmount / targetAmount : 0
    }
    
    var remaining: Double {
        targetAmount - currentAmount
    }
}

struct FinancialCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                    .font(.title2)
                .foregroundColor(color)
                
            Text("$\(amount, specifier: "%.0f")")
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

struct SpendingChartView: View {
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

struct SavingsGoalRow: View {
    let goal: SavingsGoal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("$\(goal.currentAmount, specifier: "%.0f") / $\(goal.targetAmount, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ProgressView(value: goal.progress)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .frame(width: 20, height: 20)
        }
        .padding(.vertical, 4)
    }
}

struct BudgetCategoryRow: View {
    let category: BudgetCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
        HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.color) ?? .blue)
                    .frame(width: 24)
            
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("$\(category.spent, specifier: "%.0f") / $\(category.budget, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            
            Spacer()
                
                Text("\(Int(category.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(category.progress > 0.9 ? .red : .blue)
            }
            
            ProgressView(value: category.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: category.progress > 0.9 ? .red : .blue))
        }
        .padding(.vertical, 4)
    }
}

struct ExpenseDetailRow: View {
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: expense.category.icon)
                    .foregroundColor(expense.category.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                    Text(expense.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(expense.amount, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text(expense.date, style: .date)
                    .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct SavingsGoalDetailRow: View {
    let goal: SavingsGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
        HStack {
                Image(systemName: goal.icon)
                    .foregroundColor(Color(hex: goal.color) ?? .blue)
                    .frame(width: 24)
                
            VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                    if let targetDate = goal.targetDate {
                        Text("Target: \(targetDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    }
            }
            
            Spacer()
            
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(goal.currentAmount, specifier: "%.0f")")
                    .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                
                    Text("of $\(goal.targetAmount, specifier: "%.0f")")
                    .font(.caption)
                        .foregroundColor(.secondary)
            }
            }
            
            ProgressView(value: goal.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(Int(goal.progress * 100))% complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TipRow: View {
    let tip: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb")
                .foregroundColor(.yellow)
                .frame(width: 16)
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var category = Expense.ExpenseCategory.food
    @State private var description = ""
    @State private var date = Date()
    @State private var isRecurring = false
    @State private var recurringInterval = Expense.RecurringInterval.monthly
    
    var body: some View {
        NavigationView {
            Form {
                Section("Expense Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $category) {
                        ForEach(Expense.ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
        }
    }
                    
                    TextField("Description", text: $description)
                }
                
                Section("Date & Recurring") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    
                    Toggle("Recurring Expense", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Interval", selection: $recurringInterval) {
                            ForEach(Expense.RecurringInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save expense
                        dismiss()
                    }
                    .disabled(amount.isEmpty || description.isEmpty)
                }
            }
        }
    }
}

struct AddBudgetCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var budget = ""
    @State private var selectedIcon = "circle"
    @State private var selectedColor = "blue"
    
    let icons = ["house", "car", "fork.knife", "bolt", "tv", "cross", "bag", "book", "ellipsis.circle"]
    let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                    TextField("Budget Amount", text: $budget)
                        .keyboardType(.decimalPad)
                }
                
                Section("Icon & Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color.blue : Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save category
                        dismiss()
                    }
                    .disabled(name.isEmpty || budget.isEmpty)
                }
            }
        }
    }
}

struct AddSavingsGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date()
    @State private var hasTargetDate = false
    @State private var selectedIcon = "target"
    @State private var selectedColor = "blue"
    
    let icons = ["target", "house", "car", "airplane", "graduationcap", "heart", "star", "gift"]
    let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)
                    TextField("Target Amount", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Set Target Date", isOn: $hasTargetDate)
                    
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: [.date])
                    }
                }
                
                Section("Icon & Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color.blue : Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                    )
    }
}
                    }
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save goal
                        dismiss()
                    }
                    .disabled(name.isEmpty || targetAmount.isEmpty)
                }
            }
        }
    }
} 