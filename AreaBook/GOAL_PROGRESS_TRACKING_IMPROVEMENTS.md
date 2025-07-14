# Goal and Event Progress Tracking Improvements

## Overview
This document outlines the improvements made to the goal and event creation system to enable automatic progress tracking when events and tasks are completed.

## Key Changes Made

### 1. Enhanced Goal Model (`Models.swift`)
- **Added numerical progress tracking fields:**
  - `targetValue: Int` - Total number of events/tasks needed to complete the goal
  - `currentValue: Int` - Current number of completed events/tasks
  - `progressUnit: String` - Description of what's being tracked (e.g., "events", "tasks", "sessions")

- **Added calculated progress property:**
  - `calculatedProgress: Int` - Automatically calculates progress percentage based on currentValue/targetValue

- **Updated Goal initializer:**
  - Added `targetValue` and `progressUnit` parameters to the initializer
  - Set default values: `targetValue = 1`, `progressUnit = "events"`

- **Modified property accessibility:**
  - Changed `id` and `createdAt` from `let` to `var` to support editing scenarios

### 2. Enhanced DataManager (`DataManager.swift`)
- **Added goal progress tracking method:**
  - `updateGoalProgress(goalId: String, increment: Int, userId: String)` - Updates goal progress and automatically marks as completed when target is reached

- **Added event completion method:**
  - `completeEvent(_ event: CalendarEvent, userId: String)` - Marks event as completed and updates linked goal progress

- **Added task completion method:**
  - `completeTask(_ task: Task, userId: String)` - Marks task as completed and updates linked goal progress

### 3. Enhanced Goal Creation UI (`CreateGoalView.swift`)
- **Added progress tracking section:**
  - Target value stepper control (1-999 range)
  - Progress unit selector dropdown with options: events, tasks, sessions, activities, milestones

- **Updated state management:**
  - Added `@State private var targetValue: Int = 1`
  - Added `@State private var progressUnit: String = "events"`

- **Updated save functionality:**
  - Modified `saveGoal()` to include new progress tracking fields
  - Updated `loadGoalData()` to load progress tracking fields when editing

### 4. Enhanced Goals Display (`GoalsView.swift`)
- **Updated GoalCard to show detailed progress:**
  - Displays calculated progress percentage
  - Shows current/target values with units (e.g., "3/10 events")
  - Uses `calculatedProgress` instead of manual progress field

### 5. Enhanced Event Management (`CalendarView.swift`)
- **Added event completion functionality:**
  - `toggleEventCompletion(_ event: CalendarEvent)` method
  - Updated EventCard to include completion button
  - Visual indicators for completed events (strikethrough, green checkmark)

- **Enhanced EventCard UI:**
  - Added completion toggle button
  - Added visual feedback for completed events
  - Shows completion status in the card

### 6. Enhanced Task Management (`TasksView.swift`)
- **Updated task completion logic:**
  - Modified `toggleTaskCompletion(_ task: Task)` to use new `completeTask()` method
  - Automatic goal progress update when tasks are completed
  - Maintains ability to toggle tasks back to pending

## How It Works

### Goal Creation
1. User creates a goal with a title, description, and sets:
   - Target value (number of items to complete)
   - Progress unit (what type of items: events, tasks, etc.)
2. Goal starts with `currentValue = 0` and `progress = 0`

### Event/Task Completion
1. User completes an event or task that's linked to a goal
2. System automatically:
   - Updates the event/task status to "completed"
   - Increments the linked goal's `currentValue` by 1
   - Recalculates the goal's progress percentage
   - Marks goal as completed if `currentValue >= targetValue`

### Progress Tracking
- Progress is automatically calculated as `(currentValue / targetValue) * 100`
- Goals show both percentage and fractional progress (e.g., "3/10 events")
- Visual progress bars reflect the actual completion status

## Benefits

1. **Automatic Progress Tracking**: No manual progress updates needed
2. **Clear Goal Metrics**: Users can see exactly how many events/tasks they need to complete
3. **Visual Feedback**: Immediate visual confirmation when events/tasks are completed
4. **Goal Completion**: Goals automatically complete when target is reached
5. **Flexible Units**: Support for different types of progress tracking (events, tasks, sessions, etc.)

## Future Enhancements

- Add different increment values for different types of events/tasks
- Support for weighted progress (some events worth more than others)
- Historical progress tracking and analytics
- Goal templates with pre-defined targets
- Milestone tracking within goals