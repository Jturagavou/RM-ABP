# Google Calendar Clone

A fully functional Google Calendar clone built with pure HTML, CSS, and JavaScript. This calendar application replicates the look and feel of Google Calendar with modern UI design and comprehensive event management features.

## Features

### 🎨 Modern UI Design
- Clean, Google Material Design-inspired interface
- Responsive design that works on desktop and mobile
- Smooth animations and transitions
- Google Sans font family for authentic look

### 📅 Calendar Functionality
- Monthly calendar view with intuitive navigation
- Today button to quickly jump to current date
- Previous/Next month navigation
- Clear visual indicators for today's date
- Support for other month dates (grayed out)

### 🎯 Event Management
- Create new events with title, date, time, and description
- Edit existing events
- Delete events
- Color-coded events (6 different colors)
- Event details modal with comprehensive information
- Local storage persistence (events saved between sessions)

### ⚡ Interactive Features
- Click on any date to create a new event
- Click on events to view details
- Keyboard shortcuts:
  - `t` - Go to today
  - `c` - Create new event
  - `←` / `→` - Navigate months
  - `Escape` - Close modals
- View selector (Month/Week/Day) - ready for future enhancements

### 📱 Responsive Design
- Mobile-friendly interface
- Adaptive layout for different screen sizes
- Touch-friendly buttons and interactions

## Getting Started

### Prerequisites
- A modern web browser (Chrome, Firefox, Safari, Edge)
- Python (for local server, optional)

### Installation
1. Clone or download the repository
2. Open the project folder
3. Run a local server (optional but recommended):
   ```bash
   python -m http.server 8000
   ```
4. Open your browser and navigate to `http://localhost:8000`
5. Or simply open `index.html` directly in your browser

### Usage
1. **Navigate the calendar**: Use the arrow buttons or keyboard shortcuts to move between months
2. **Create events**: Click the "Create" button or click on any date
3. **View events**: Click on any event to see its details
4. **Edit events**: Click the edit button in the event details modal
5. **Delete events**: Click the delete button in the event details modal

## File Structure
```
├── index.html          # Main HTML structure
├── styles.css          # Google Calendar-inspired styling
├── calendar.js         # Core calendar functionality
├── package.json        # Project configuration
└── README.md          # This file
```

## Technical Details

### Built With
- **HTML5**: Semantic markup and structure
- **CSS3**: Modern styling with Grid and Flexbox
- **JavaScript (ES6+)**: Object-oriented programming with classes
- **Google Fonts**: Google Sans font family
- **Material Icons**: Google Material Design icons

### Key Components
- `GoogleCalendar` class: Main calendar functionality
- `CalendarUtils` class: Utility functions for date manipulation
- Local storage: Persistent event storage
- Modal system: Event creation and editing interfaces

### Browser Support
- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## Contributing
Feel free to submit issues and enhancement requests!

## License
This project is licensed under the MIT License.

## Acknowledgments
- Inspired by Google Calendar's design and functionality
- Uses Google Fonts and Material Icons
- Built with modern web standards
