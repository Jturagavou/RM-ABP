import Foundation
import UIKit
import Vision
import VisionKit

// MARK: - OCR Service for Calendar Image Processing
class OCRService: ObservableObject {
    static let shared = OCRService()
    
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Text Recognition
    
    /// Extract text from a calendar image using Vision framework
    func extractText(from image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.isProcessing = true
            }
            
            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Failed to process image"
                }
                continuation.resume(throwing: OCRError.invalidImage)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "OCR failed: \(error.localizedDescription)"
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Configure request for better calendar recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Vision processing failed: \(error.localizedDescription)"
                }
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Extract structured calendar information from text
    func parseCalendarInfo(from text: String) -> CalendarExtractionResult {
        var events: [ExtractedEvent] = []
        var dates: [ExtractedDate] = []
        var times: [ExtractedTime] = []
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            // Extract dates
            if let date = extractDate(from: line) {
                dates.append(date)
            }
            
            // Extract times
            let extractedTimes = extractTimes(from: line)
            times.append(contentsOf: extractedTimes)
            
            // Try to extract complete events
            if let event = extractEvent(from: line) {
                events.append(event)
            }
        }
        
        return CalendarExtractionResult(
            originalText: text,
            extractedEvents: events,
            extractedDates: dates,
            extractedTimes: times,
            confidence: calculateConfidence(events: events, dates: dates, times: times)
        )
    }
    
    // MARK: - Private Parsing Methods
    
    private func extractDate(from text: String) -> ExtractedDate? {
        let datePatterns = [
            // MM/DD/YYYY or MM-DD-YYYY
            #"(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})"#,
            // Month DD, YYYY
            #"(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s+(\d{4})"#,
            // Mon DD or Monday DD
            #"(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s+(\d{1,2})"#,
            // DD Month YYYY
            #"(\d{1,2})\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})"#
        ]
        
        for pattern in datePatterns {
            if let match = text.range(of: pattern, options: .regularExpression, locale: .current) {
                let matchedText = String(text[match])
                if let date = parseDate(from: matchedText) {
                    return ExtractedDate(
                        originalText: matchedText,
                        date: date,
                        confidence: 0.8
                    )
                }
            }
        }
        
        return nil
    }
    
    private func extractTimes(from text: String) -> [ExtractedTime] {
        let timePattern = #"(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?"#
        var times: [ExtractedTime] = []
        
        let regex = try? NSRegularExpression(pattern: timePattern)
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        for match in matches {
            if let range = Range(match.range, in: text) {
                let timeString = String(text[range])
                if let time = parseTime(from: timeString) {
                    times.append(ExtractedTime(
                        originalText: timeString,
                        time: time,
                        confidence: 0.9
                    ))
                }
            }
        }
        
        return times
    }
    
    private func extractEvent(from text: String) -> ExtractedEvent? {
        // Simple heuristic: if line contains both date/time and descriptive text
        let hasDate = extractDate(from: text) != nil
        let hasTime = !extractTimes(from: text).isEmpty
        
        if hasDate || hasTime {
            // Remove date/time parts to get event title
            var title = text
            
            // Remove common date patterns
            let cleaningPatterns = [
                #"\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}"#,
                #"\d{1,2}:\d{2}\s*(AM|PM|am|pm)?"#,
                #"(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}"#
            ]
            
            for pattern in cleaningPatterns {
                title = title.replacingOccurrences(
                    of: pattern,
                    with: "",
                    options: .regularExpression
                ).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            if !title.isEmpty && title.count > 3 {
                return ExtractedEvent(
                    title: title,
                    originalText: text,
                    extractedDate: extractDate(from: text),
                    extractedTimes: extractTimes(from: text),
                    confidence: 0.7
                )
            }
        }
        
        return nil
    }
    
    private func parseDate(from text: String) -> Date? {
        let formatters = [
            DateFormatter().configured {
                $0.dateFormat = "MM/dd/yyyy"
            },
            DateFormatter().configured {
                $0.dateFormat = "MM-dd-yyyy"
            },
            DateFormatter().configured {
                $0.dateFormat = "MMMM dd, yyyy"
            },
            DateFormatter().configured {
                $0.dateFormat = "dd MMMM yyyy"
            }
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: text) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseTime(from text: String) -> Date? {
        let formatter = DateFormatter()
        
        // Try different time formats
        let formats = ["h:mm a", "HH:mm", "h:mm"]
        
        for format in formats {
            formatter.dateFormat = format
            if let time = formatter.date(from: text) {
                return time
            }
        }
        
        return nil
    }
    
    private func calculateConfidence(events: [ExtractedEvent], dates: [ExtractedDate], times: [ExtractedTime]) -> Double {
        let eventCount = events.count
        let dateCount = dates.count
        let timeCount = times.count
        
        if eventCount > 0 {
            return 0.9
        } else if dateCount > 0 && timeCount > 0 {
            return 0.8
        } else if dateCount > 0 || timeCount > 0 {
            return 0.6
        } else {
            return 0.2
        }
    }
}

// MARK: - Data Models

struct CalendarExtractionResult {
    let originalText: String
    let extractedEvents: [ExtractedEvent]
    let extractedDates: [ExtractedDate]
    let extractedTimes: [ExtractedTime]
    let confidence: Double
    
    var hasUsefulData: Bool {
        return !extractedEvents.isEmpty || !extractedDates.isEmpty || !extractedTimes.isEmpty
    }
}

struct ExtractedEvent {
    let title: String
    let originalText: String
    let extractedDate: ExtractedDate?
    let extractedTimes: [ExtractedTime]
    let confidence: Double
}

struct ExtractedDate {
    let originalText: String
    let date: Date
    let confidence: Double
}

struct ExtractedTime {
    let originalText: String
    let time: Date
    let confidence: Double
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case visionFrameworkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        case .visionFrameworkError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    func configured(_ configuration: (DateFormatter) -> Void) -> DateFormatter {
        configuration(self)
        return self
    }
}