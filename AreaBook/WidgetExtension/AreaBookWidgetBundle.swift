import WidgetKit
import SwiftUI

@main
struct AreaBookWidgetBundle: WidgetBundle {
    var body: some Widget {
        AreaBookWidget()
        KIProgressWidget()
        WellnessWidget()
        TasksWidget()
        GoalsWidget()
    }
} 