# AreaBook iOS Widget Extension Setup

This document explains how to set up the iOS widget extension for AreaBook.

## Overview

The AreaBook app includes a comprehensive iOS widget system that allows users to add widgets to their iPhone home screen. The widgets provide quick access to key data without opening the app.

## Available Widgets

1. **AreaBook Dashboard** - Overview of key indicators, tasks, and events (Small, Medium, Large)
2. **Key Indicators** - Track weekly progress on key metrics (Small, Medium)
3. **Wellness Tracker** - Monitor mood, meditation, and wellness activities (Small, Medium)
4. **Today's Tasks** - Quick view of daily tasks and priorities (Small, Medium)
5. **Goal Progress** - Track progress on personal goals (Small, Medium)

## Setup Instructions

### 1. Create Widget Extension Target

1. Open the AreaBook project in Xcode
2. Go to File → New → Target
3. Select "Widget Extension" under iOS
4. Name it "AreaBookWidgetExtension"
5. Make sure "Include Configuration Intent" is unchecked
6. Click "Finish"

### 2. Configure App Groups

1. Select the main AreaBook target
2. Go to Signing & Capabilities
3. Click "+ Capability" and add "App Groups"
4. Create a group: `group.com.areabook.app`
5. Repeat for the widget extension target

### 3. Update Bundle Identifiers

- Main App: `com.areabook.app`
- Widget Extension: `com.areabook.app.widget`

### 4. Copy Widget Files

Copy the following files to the widget extension target:
- `AreaBookWidgetBundle.swift` (replace the default)
- `AreaBookWidget.swift`
- `WidgetDataModels.swift` (shared)

### 5. Update Info.plist

Ensure the widget extension's Info.plist includes:
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

### 6. Build and Test

1. Build the project
2. Run the main app on a device
3. Long press the home screen
4. Tap the "+" button
5. Search for "AreaBook"
6. Add widgets to test

## Data Sharing

The widgets use App Groups to share data with the main app:

- **Shared UserDefaults**: `group.com.areabook.app`
- **Data Keys**: Defined in `WidgetDataKeys`
- **Sync Service**: `WidgetDataService` handles data synchronization

## Widget Features

### Real-time Updates
- Widgets update every 15 minutes by default
- Data syncs automatically when the main app is active
- Users can manually refresh widget data

### Customization
- Multiple widget sizes (Small, Medium, Large)
- Theme support (System, Light, Dark)
- Configurable refresh intervals
- Widget-specific preferences

### Data Types
- Key Indicators with progress tracking
- Today's tasks with priority indicators
- Calendar events with time display
- Goal progress with percentage completion
- Wellness data (mood, meditation, water, sleep)

## Troubleshooting

### Common Issues

1. **Widgets not showing data**
   - Check App Groups configuration
   - Verify data is being saved to shared UserDefaults
   - Ensure the main app has synced data

2. **Widgets not updating**
   - Check refresh interval settings
   - Verify real-time updates are enabled
   - Restart the widget extension

3. **Build errors**
   - Ensure all shared files are included in both targets
   - Check bundle identifiers and App Groups
   - Verify Info.plist configuration

### Debug Tips

1. Use Xcode's widget preview to test layouts
2. Check console logs for data sync issues
3. Test on physical device (widgets don't work in simulator)
4. Use WidgetDataUtilities for consistent data access

## Future Enhancements

- Interactive widgets (iOS 17+)
- Widget complications for Apple Watch
- Custom widget themes
- Widget analytics and usage tracking
- More widget types (notes, groups, etc.)

## Support

For widget-related issues:
1. Check the widget settings in the main app
2. Use the "Reset Widget Data" option
3. Contact support through the app
4. Review this documentation 