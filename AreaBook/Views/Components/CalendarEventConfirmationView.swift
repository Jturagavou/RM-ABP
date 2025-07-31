import SwiftUI

// MARK: - Calendar Event Confirmation View
struct CalendarEventConfirmationView: View {
    let result: CalendarProcessingResult
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var selectedEvents: Set<String> = []
    @State private var editingEvent: CalendarEvent?
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with image preview
                    headerSection
                    
                    // Processing results summary
                    resultsSection
                    
                    // Events list
                    eventsSection
                    
                    // Action buttons
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Confirm Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            if let event = editingEvent {
                EventEditView(
                    event: event,
                    onSave: { updatedEvent in
                        // Update the event in the result
                        updateEvent(updatedEvent)
                        showingEditView = false
                    },
                    onCancel: {
                        showingEditView = false
                    }
                )
            }
        }
        .onAppear {
            // Select all events by default
            selectedEvents = Set(result.calendarEvents.map { $0.id })
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Image preview
            Image(uiImage: result.originalImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            Text("I found events in your calendar image")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
    }
    
    private var resultsSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Processing Results")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Confidence: \(String(format: "%.0f", result.ocrResult.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(result.calendarEvents.count) Events")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(selectedEvents.count) Selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Events to Add")
                    .font(.headline)
                
                Spacer()
                
                Button(selectedEvents.count == result.calendarEvents.count ? "Deselect All" : "Select All") {
                    if selectedEvents.count == result.calendarEvents.count {
                        selectedEvents.removeAll()
                    } else {
                        selectedEvents = Set(result.calendarEvents.map { $0.id })
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(result.calendarEvents, id: \.id) { event in
                    EventConfirmationCard(
                        event: event,
                        isSelected: selectedEvents.contains(event.id),
                        onToggleSelection: {
                            if selectedEvents.contains(event.id) {
                                selectedEvents.remove(event.id)
                            } else {
                                selectedEvents.insert(event.id)
                            }
                        },
                        onEdit: {
                            editingEvent = event
                            showingEditView = true
                        }
                    )
                }
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Filter events based on selection
                let eventsToAdd = result.calendarEvents.filter { selectedEvents.contains($0.id) }
                if !eventsToAdd.isEmpty {
                    onConfirm()
                }
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add \(selectedEvents.count) Event\(selectedEvents.count == 1 ? "" : "s")")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedEvents.isEmpty ? Color(.systemGray4) : Color.accentColor)
                .foregroundColor(selectedEvents.isEmpty ? .secondary : .white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedEvents.isEmpty)
            
            Button("Review Original Text") {
                // Could show a sheet with the extracted text
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateEvent(_ updatedEvent: CalendarEvent) {
        // This would need to update the result's events
        // For now, we'll just keep the original implementation
    }
}

// MARK: - Event Confirmation Card
struct EventConfirmationCard: View {
    let event: CalendarEvent
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Event title
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Date and time
                HStack(spacing: 16) {
                    Label(formatDate(event.startTime), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !event.isAllDay {
                        Label(formatTime(event.startTime, to: event.endTime), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Category and location
                HStack(spacing: 16) {
                    Label(event.category, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if let location = event.location, !location.isEmpty {
                        Label(location, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Description if available
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isSelected ? 1.0 : 0.7)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ startDate: Date, to endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startTime = formatter.string(from: startDate)
        let endTime = formatter.string(from: endDate)
        return "\(startTime) - \(endTime)"
    }
}

// MARK: - Simple Event Edit View
struct EventEditView: View {
    let event: CalendarEvent
    let onSave: (CalendarEvent) -> Void
    let onCancel: () -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay: Bool
    @State private var category: String
    @State private var location: String
    
    init(event: CalendarEvent, onSave: @escaping (CalendarEvent) -> Void, onCancel: @escaping () -> Void) {
        self.event = event
        self.onSave = onSave
        self.onCancel = onCancel
        
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description ?? "")
        _startDate = State(initialValue: event.startTime)
        _endDate = State(initialValue: event.endTime)
        _isAllDay = State(initialValue: event.isAllDay)
        _category = State(initialValue: event.category)
        _location = State(initialValue: event.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Date & Time") {
                    Toggle("All Day", isOn: $isAllDay)
                    
                    DatePicker("Start", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    
                    if !isAllDay {
                        DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Additional Info") {
                    TextField("Category", text: $category)
                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveEvent() {
        var updatedEvent = event
        updatedEvent.title = title
        updatedEvent.description = description.isEmpty ? nil : description
        updatedEvent.startTime = startDate
        updatedEvent.endTime = isAllDay ? startDate : endDate
        updatedEvent.isAllDay = isAllDay
        updatedEvent.category = category
        updatedEvent.location = location.isEmpty ? nil : location
        updatedEvent.updatedAt = Date()
        
        onSave(updatedEvent)
    }
}