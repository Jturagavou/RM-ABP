import Foundation
import FirebaseAuth

// MARK: - AI Calendar Parser Service
class AICalendarParser: ObservableObject {
    static let shared = AICalendarParser()
    
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let gptService = GPTService.shared
    private let ocrService = OCRService.shared
    
    private init() {}
    
    // MARK: - Main Processing Pipeline
    
    /// Complete pipeline: Image -> OCR -> AI Parsing -> Calendar Events
    func processCalendarImage(_ image: UIImage) async throws -> CalendarProcessingResult {
        DispatchQueue.main.async {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        do {
            // Step 1: Extract text using OCR
            let extractedText = try await ocrService.extractText(from: image)
            
            // Step 2: Parse calendar information from text
            let ocrResult = ocrService.parseCalendarInfo(from: extractedText)
            
            // Step 3: Use AI to intelligently parse and create events
            let aiParsedEvents = try await parseWithAI(
                extractedText: extractedText,
                ocrResult: ocrResult
            )
            
            // Step 4: Convert to CalendarEvent objects
            let calendarEvents = try await convertToCalendarEvents(aiParsedEvents)
            
            let result = CalendarProcessingResult(
                originalImage: image,
                extractedText: extractedText,
                ocrResult: ocrResult,
                aiParsedEvents: aiParsedEvents,
                calendarEvents: calendarEvents,
                processingSuccess: true
            )
            
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            
            return result
            
        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - AI Processing
    
    private func parseWithAI(extractedText: String, ocrResult: CalendarExtractionResult) async throws -> [AIParsedEvent] {
        let prompt = createCalendarParsingPrompt(text: extractedText, ocrResult: ocrResult)
        
        let response = try await gptService.generateResponse(
            prompt: prompt,
            context: "Calendar image parsing",
            userRole: .personal,
            assistantStyle: .helpful
        )
        
        return try parseAIResponse(response)
    }
    
    private func createCalendarParsingPrompt(text: String, ocrResult: CalendarExtractionResult) -> String {
        let currentDate = DateFormatter().string(from: Date())
        
        return """
        I'm analyzing text extracted from a calendar image. Please parse this text and identify all calendar events, meetings, appointments, or scheduled activities.
        
        Current Date: \(currentDate)
        
        Extracted Text:
        \(text)
        
        OCR Analysis Summary:
        - Found \(ocrResult.extractedDates.count) dates
        - Found \(ocrResult.extractedTimes.count) times
        - Found \(ocrResult.extractedEvents.count) potential events
        - Confidence: \(String(format: "%.1f", ocrResult.confidence * 100))%
        
        Please respond with a JSON array of events in this exact format:
        [
          {
            "title": "Event title",
            "description": "Optional description or details",
            "date": "YYYY-MM-DD",
            "startTime": "HH:MM" (24-hour format),
            "endTime": "HH:MM" (24-hour format, optional),
            "isAllDay": false,
            "category": "Personal|Work|Health|Other",
            "location": "Optional location",
            "confidence": 0.9 (0.0-1.0)
          }
        ]
        
        Rules:
        1. Only include events that are clearly identifiable
        2. If no specific year is mentioned, assume current year
        3. If no end time is given, estimate a reasonable duration
        4. Use "Personal" category unless clearly work/health related
        5. If confidence is below 0.6, include but mark as low confidence
        6. Combine related information from multiple lines if needed
        7. Don't include headers, footers, or non-event text
        
        Return only the JSON array, no other text.
        """
    }
    
    private func parseAIResponse(_ response: String) throws -> [AIParsedEvent] {
        // Clean up response to extract just JSON
        let cleanResponse = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanResponse.data(using: .utf8) else {
            throw AICalendarError.invalidResponse
        }
        
        do {
            let events = try JSONDecoder().decode([AIParsedEvent].self, from: data)
            return events
        } catch {
            print("Failed to parse AI response: \(error)")
            print("Response was: \(cleanResponse)")
            throw AICalendarError.parsingFailed(error)
        }
    }
    
    private func convertToCalendarEvents(_ aiEvents: [AIParsedEvent]) async throws -> [CalendarEvent] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AICalendarError.userNotAuthenticated
        }
        
        var calendarEvents: [CalendarEvent] = []
        
        for aiEvent in aiEvents {
            do {
                let calendarEvent = try createCalendarEvent(from: aiEvent, userId: userId)
                calendarEvents.append(calendarEvent)
            } catch {
                print("Failed to convert AI event to calendar event: \(error)")
                // Continue with other events
            }
        }
        
        return calendarEvents
    }
    
    private func createCalendarEvent(from aiEvent: AIParsedEvent, userId: String) throws -> CalendarEvent {
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let eventDate = dateFormatter.date(from: aiEvent.date) else {
            throw AICalendarError.invalidDate(aiEvent.date)
        }
        
        // Parse times
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        var startDateTime = eventDate
        var endDateTime = eventDate
        
        if !aiEvent.isAllDay {
            if let startTime = timeFormatter.date(from: aiEvent.startTime) {
                startDateTime = Calendar.current.date(
                    bySettingHour: Calendar.current.component(.hour, from: startTime),
                    minute: Calendar.current.component(.minute, from: startTime),
                    second: 0,
                    of: eventDate
                ) ?? eventDate
            }
            
            if let endTimeString = aiEvent.endTime,
               let endTime = timeFormatter.date(from: endTimeString) {
                endDateTime = Calendar.current.date(
                    bySettingHour: Calendar.current.component(.hour, from: endTime),
                    minute: Calendar.current.component(.minute, from: endTime),
                    second: 0,
                    of: eventDate
                ) ?? Calendar.current.date(byAdding: .hour, value: 1, to: startDateTime) ?? startDateTime
            } else {
                // Default to 1 hour duration
                endDateTime = Calendar.current.date(byAdding: .hour, value: 1, to: startDateTime) ?? startDateTime
            }
        }
        
        // Map category
        let eventCategory = mapCategory(aiEvent.category)
        
        // Create CalendarEvent
        return CalendarEvent(
            id: UUID().uuidString,
            userId: userId,
            title: aiEvent.title,
            description: aiEvent.description,
            startTime: startDateTime,
            endTime: endDateTime,
            isAllDay: aiEvent.isAllDay,
            category: eventCategory,
            location: aiEvent.location,
            reminderMinutes: 15, // Default reminder
            recurrenceType: .none,
            linkedGoalIds: [],
            linkedTaskIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func mapCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "work", "business", "meeting", "office":
            return "Work"
        case "health", "medical", "doctor", "appointment":
            return "Health"
        case "personal", "family", "social":
            return "Personal"
        case "school", "education", "class":
            return "School"
        default:
            return "Other"
        }
    }
}

// MARK: - Data Models

struct CalendarProcessingResult {
    let originalImage: UIImage
    let extractedText: String
    let ocrResult: CalendarExtractionResult
    let aiParsedEvents: [AIParsedEvent]
    let calendarEvents: [CalendarEvent]
    let processingSuccess: Bool
    
    var hasEvents: Bool {
        return !calendarEvents.isEmpty
    }
    
    var summary: String {
        if hasEvents {
            return "Found \(calendarEvents.count) event\(calendarEvents.count == 1 ? "" : "s")"
        } else {
            return "No events found"
        }
    }
}

struct AIParsedEvent: Codable {
    let title: String
    let description: String?
    let date: String // YYYY-MM-DD format
    let startTime: String // HH:MM format
    let endTime: String? // HH:MM format, optional
    let isAllDay: Bool
    let category: String
    let location: String?
    let confidence: Double
}

// MARK: - Errors

enum AICalendarError: LocalizedError {
    case userNotAuthenticated
    case invalidResponse
    case parsingFailed(Error)
    case invalidDate(String)
    case invalidTime(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid AI response format"
        case .parsingFailed(let error):
            return "Failed to parse AI response: \(error.localizedDescription)"
        case .invalidDate(let date):
            return "Invalid date format: \(date)"
        case .invalidTime(let time):
            return "Invalid time format: \(time)"
        }
    }
}