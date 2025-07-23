import Foundation
import UIKit

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func lightImpact() {
        impact(style: .light)
    }
    
    func mediumImpact() {
        impact(style: .medium)
    }
    
    func heavyImpact() {
        impact(style: .heavy)
    }
    
    func softImpact() {
        impact(style: .soft)
    }
    
    func rigidImpact() {
        impact(style: .rigid)
    }
    
    // MARK: - Notification Feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func success() {
        notification(type: .success)
    }
    
    func warning() {
        notification(type: .warning)
    }
    
    func error() {
        notification(type: .error)
    }
    
    // MARK: - Selection Feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Feedback Patterns
    func doubleTap() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    func longPress() {
        mediumImpact()
    }
    
    func dragStart() {
        lightImpact()
    }
    
    func dragEnd() {
        mediumImpact()
    }
    
    func widgetAdded() {
        success()
    }
    
    func widgetRemoved() {
        warning()
    }
    
    func taskCompleted() {
        success()
    }
    
    func goalUpdated() {
        mediumImpact()
    }
    
    func progressIncremented() {
        lightImpact()
    }
    
    func errorOccurred() {
        error()
    }
    
    func dataSaved() {
        success()
    }
    
    func dataDeleted() {
        warning()
    }
    
    func tabSwitched() {
        lightImpact()
    }
    
    func buttonPressed() {
        lightImpact()
    }
    
    func toggleChanged() {
        lightImpact()
    }
    
    func sliderChanged() {
        lightImpact()
    }
    
    func pickerChanged() {
        lightImpact()
    }
    
    func refreshStarted() {
        lightImpact()
    }
    
    func refreshCompleted() {
        success()
    }
    
    func searchStarted() {
        lightImpact()
    }
    
    func searchCompleted() {
        lightImpact()
    }
    
    func formSubmitted() {
        success()
    }
    
    func formValidationError() {
        error()
    }
    
    func authenticationSuccess() {
        success()
    }
    
    func authenticationFailure() {
        error()
    }
    
    func syncStarted() {
        lightImpact()
    }
    
    func syncCompleted() {
        success()
    }
    
    func syncFailed() {
        error()
    }
    
    func groupJoined() {
        success()
    }
    
    func groupLeft() {
        warning()
    }
    
    func challengeCompleted() {
        success()
    }
    
    func milestoneReached() {
        success()
    }
    
    func streakBroken() {
        error()
    }
    
    func streakContinued() {
        success()
    }
}

// MARK: - SwiftUI Haptic Feedback Modifier
struct HapticFeedbackModifier: ViewModifier {
    let feedback: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                feedback()
            }
    }
}

extension View {
    func hapticFeedback(_ feedback: @escaping () -> Void) -> some View {
        modifier(HapticFeedbackModifier(feedback: feedback))
    }
    
    func hapticButton() -> some View {
        self.hapticFeedback {
            HapticManager.shared.buttonPressed()
        }
    }
    
    func hapticSuccess() -> some View {
        self.hapticFeedback {
            HapticManager.shared.success()
        }
    }
    
    func hapticError() -> some View {
        self.hapticFeedback {
            HapticManager.shared.error()
        }
    }
    
    func hapticWarning() -> some View {
        self.hapticFeedback {
            HapticManager.shared.warning()
        }
    }
    
    func hapticLight() -> some View {
        self.hapticFeedback {
            HapticManager.shared.lightImpact()
        }
    }
    
    func hapticMedium() -> some View {
        self.hapticFeedback {
            HapticManager.shared.mediumImpact()
        }
    }
    
    func hapticHeavy() -> some View {
        self.hapticFeedback {
            HapticManager.shared.heavyImpact()
        }
    }
} 