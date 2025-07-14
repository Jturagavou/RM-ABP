import SwiftUI

enum CalendarViewType: String, CaseIterable {
    case month = "Month"
    case day = "Day"
    case week = "Week"
}

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedDate = Date()
    @State private var selectedView: CalendarViewType = .month
    @State private var showingEventCreation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // View Switcher
                viewSwitcher
                
                // Calendar Content
                Group {
                    switch selectedView {
                    case .month:
                        monthView
                    case .day:
                        DayView()
                    case .week:
                        WeekView()
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingEventCreation = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingEventCreation) {
                CreateEventView()
            }
        }
    }
    
    private var viewSwitcher: some View {
        HStack {
            Picker("View", selection: $selectedView) {
                ForEach(CalendarViewType.allCases, id: \.self) { viewType in
                    Text(viewType.rawValue).tag(viewType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var monthView: some View {
        VStack {
            // Calendar Widget
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            
            // Events for selected date
            ScrollView {
                LazyVStack(spacing: 12) {
                    let eventsForDate = eventsForSelectedDate
                    
                    if eventsForDate.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Events")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("No events scheduled for \(selectedDate, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(eventsForDate) { event in
                            EventCard(event: event)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        dataManager.events.filter { event in
            Calendar.current.isDate(event.startTime, inSameDayAs: selectedDate)
        }
        .sorted { $0.startTime < $1.startTime }
    }
}

struct EventCard: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(event.startTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(event.endTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 60)
            
            Rectangle()
                .fill(Color.blue)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(event.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    CalendarView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}