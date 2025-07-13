// Google Calendar Clone JavaScript
class GoogleCalendar {
    constructor() {
        this.currentDate = new Date();
        this.today = new Date();
        this.events = JSON.parse(localStorage.getItem('calendar-events')) || [];
        this.currentView = 'month';
        this.selectedDate = null;
        this.editingEvent = null;
        
        this.init();
    }

    init() {
        this.renderCalendar();
        this.bindEvents();
        this.updateMonthYear();
        this.addSampleEvents();
    }

    bindEvents() {
        // Navigation buttons
        document.getElementById('prevBtn').addEventListener('click', () => this.navigateMonth(-1));
        document.getElementById('nextBtn').addEventListener('click', () => this.navigateMonth(1));
        document.getElementById('todayBtn').addEventListener('click', () => this.goToToday());

        // View selector
        document.querySelectorAll('.view-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.changeView(e.target.dataset.view));
        });

        // Create button
        document.querySelector('.create-btn').addEventListener('click', () => this.openEventModal());

        // Modal events
        document.getElementById('closeModal').addEventListener('click', () => this.closeModal());
        document.getElementById('closeDetailsModal').addEventListener('click', () => this.closeDetailsModal());
        document.getElementById('cancelBtn').addEventListener('click', () => this.closeModal());
        document.getElementById('eventForm').addEventListener('submit', (e) => this.handleEventSubmit(e));

        // Event details modal
        document.getElementById('editEventBtn').addEventListener('click', () => this.editEvent());
        document.getElementById('deleteEventBtn').addEventListener('click', () => this.deleteEvent());

        // Close modals on overlay click
        document.getElementById('eventModal').addEventListener('click', (e) => {
            if (e.target === e.currentTarget) this.closeModal();
        });
        document.getElementById('eventDetailsModal').addEventListener('click', (e) => {
            if (e.target === e.currentTarget) this.closeDetailsModal();
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeyboard(e));
    }

    renderCalendar() {
        const calendarDates = document.getElementById('calendarDates');
        calendarDates.innerHTML = '';

        const firstDay = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth(), 1);
        const lastDay = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 0);
        const startDate = new Date(firstDay);
        startDate.setDate(startDate.getDate() - firstDay.getDay());

        for (let i = 0; i < 42; i++) {
            const date = new Date(startDate);
            date.setDate(startDate.getDate() + i);
            
            const dayElement = this.createDayElement(date);
            calendarDates.appendChild(dayElement);
        }
    }

    createDayElement(date) {
        const dayElement = document.createElement('div');
        dayElement.className = 'calendar-day';
        
        const isCurrentMonth = date.getMonth() === this.currentDate.getMonth();
        const isToday = this.isSameDate(date, this.today);
        const isSelected = this.selectedDate && this.isSameDate(date, this.selectedDate);

        if (!isCurrentMonth) {
            dayElement.classList.add('other-month');
        }
        if (isToday) {
            dayElement.classList.add('today');
        }
        if (isSelected) {
            dayElement.classList.add('selected');
        }

        const dayNumber = document.createElement('div');
        dayNumber.className = 'day-number';
        dayNumber.textContent = date.getDate();

        const eventsContainer = document.createElement('div');
        eventsContainer.className = 'events-container';

        const dayEvents = this.getEventsForDate(date);
        dayEvents.forEach((event, index) => {
            if (index < 3) { // Show max 3 events
                const eventElement = document.createElement('div');
                eventElement.className = `event-item ${this.getColorClass(event.color)}`;
                eventElement.textContent = event.title;
                eventElement.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.showEventDetails(event);
                });
                eventsContainer.appendChild(eventElement);
            }
        });

        if (dayEvents.length > 3) {
            const moreEvents = document.createElement('div');
            moreEvents.className = 'more-events';
            moreEvents.textContent = `+${dayEvents.length - 3} more`;
            eventsContainer.appendChild(moreEvents);
        }

        dayElement.appendChild(dayNumber);
        dayElement.appendChild(eventsContainer);

        dayElement.addEventListener('click', () => this.selectDate(date));

        return dayElement;
    }

    getEventsForDate(date) {
        return this.events.filter(event => {
            const eventDate = new Date(event.date);
            return this.isSameDate(eventDate, date);
        });
    }

    getColorClass(color) {
        const colorMap = {
            '#4285f4': 'blue',
            '#34a853': 'green',
            '#ea4335': 'red',
            '#fbbc04': 'yellow',
            '#9c27b0': 'purple',
            '#ff9800': 'orange'
        };
        return colorMap[color] || 'blue';
    }

    selectDate(date) {
        this.selectedDate = date;
        this.renderCalendar();
        this.openEventModal(date);
    }

    navigateMonth(direction) {
        this.currentDate.setMonth(this.currentDate.getMonth() + direction);
        this.renderCalendar();
        this.updateMonthYear();
    }

    goToToday() {
        this.currentDate = new Date();
        this.renderCalendar();
        this.updateMonthYear();
    }

    updateMonthYear() {
        const monthYear = document.getElementById('monthYear');
        const options = { month: 'long', year: 'numeric' };
        monthYear.textContent = this.currentDate.toLocaleDateString('en-US', options);
    }

    changeView(view) {
        this.currentView = view;
        document.querySelectorAll('.view-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-view="${view}"]`).classList.add('active');
        
        // For now, all views show the month view
        // In a full implementation, you'd have different layouts for week and day views
        this.renderCalendar();
    }

    openEventModal(date = null) {
        const modal = document.getElementById('eventModal');
        const form = document.getElementById('eventForm');
        
        if (date) {
            document.getElementById('eventDate').value = this.formatDateForInput(date);
        } else if (this.selectedDate) {
            document.getElementById('eventDate').value = this.formatDateForInput(this.selectedDate);
        } else {
            document.getElementById('eventDate').value = this.formatDateForInput(new Date());
        }
        
        if (this.editingEvent) {
            document.getElementById('modalTitle').textContent = 'Edit Event';
            document.getElementById('eventTitle').value = this.editingEvent.title;
            document.getElementById('eventDate').value = this.formatDateForInput(new Date(this.editingEvent.date));
            document.getElementById('eventTime').value = this.editingEvent.time || '';
            document.getElementById('eventDescription').value = this.editingEvent.description || '';
            document.getElementById('eventColor').value = this.editingEvent.color;
        } else {
            document.getElementById('modalTitle').textContent = 'Add Event';
            form.reset();
            document.getElementById('eventColor').value = '#4285f4';
        }
        
        modal.classList.add('active');
        document.getElementById('eventTitle').focus();
    }

    closeModal() {
        document.getElementById('eventModal').classList.remove('active');
        this.editingEvent = null;
        this.selectedDate = null;
        this.renderCalendar();
    }

    handleEventSubmit(e) {
        e.preventDefault();
        
        const eventData = {
            id: this.editingEvent?.id || Date.now(),
            title: document.getElementById('eventTitle').value,
            date: document.getElementById('eventDate').value,
            time: document.getElementById('eventTime').value,
            description: document.getElementById('eventDescription').value,
            color: document.getElementById('eventColor').value
        };

        if (this.editingEvent) {
            const index = this.events.findIndex(event => event.id === this.editingEvent.id);
            this.events[index] = eventData;
        } else {
            this.events.push(eventData);
        }

        this.saveEvents();
        this.renderCalendar();
        this.closeModal();
    }

    showEventDetails(event) {
        this.editingEvent = event;
        const modal = document.getElementById('eventDetailsModal');
        
        document.getElementById('eventDetailsTitle').textContent = event.title;
        
        const eventDate = new Date(event.date);
        const timeString = event.time ? 
            `${eventDate.toLocaleDateString()} at ${this.formatTime(event.time)}` : 
            eventDate.toLocaleDateString();
        document.getElementById('eventDetailsTime').textContent = timeString;
        
        const descElement = document.getElementById('eventDetailsDesc');
        if (event.description) {
            document.getElementById('eventDetailsDescription').textContent = event.description;
            descElement.style.display = 'flex';
        } else {
            descElement.style.display = 'none';
        }
        
        modal.classList.add('active');
    }

    closeDetailsModal() {
        document.getElementById('eventDetailsModal').classList.remove('active');
        this.editingEvent = null;
    }

    editEvent() {
        this.closeDetailsModal();
        this.openEventModal();
    }

    deleteEvent() {
        if (this.editingEvent) {
            const index = this.events.findIndex(event => event.id === this.editingEvent.id);
            this.events.splice(index, 1);
            this.saveEvents();
            this.renderCalendar();
            this.closeDetailsModal();
        }
    }

    handleKeyboard(e) {
        if (e.key === 'Escape') {
            this.closeModal();
            this.closeDetailsModal();
        }
        
        if (e.key === 'ArrowLeft' && !e.target.matches('input, textarea')) {
            e.preventDefault();
            this.navigateMonth(-1);
        }
        
        if (e.key === 'ArrowRight' && !e.target.matches('input, textarea')) {
            e.preventDefault();
            this.navigateMonth(1);
        }
        
        if (e.key === 't' && !e.target.matches('input, textarea')) {
            e.preventDefault();
            this.goToToday();
        }
        
        if (e.key === 'c' && !e.target.matches('input, textarea')) {
            e.preventDefault();
            this.openEventModal();
        }
    }

    formatDateForInput(date) {
        return date.toISOString().split('T')[0];
    }

    formatTime(time) {
        const [hours, minutes] = time.split(':');
        const hour = parseInt(hours);
        const ampm = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour % 12 || 12;
        return `${displayHour}:${minutes} ${ampm}`;
    }

    isSameDate(date1, date2) {
        return date1.getFullYear() === date2.getFullYear() &&
               date1.getMonth() === date2.getMonth() &&
               date1.getDate() === date2.getDate();
    }

    saveEvents() {
        localStorage.setItem('calendar-events', JSON.stringify(this.events));
    }

    addSampleEvents() {
        // Add some sample events if none exist
        if (this.events.length === 0) {
            const today = new Date();
            const tomorrow = new Date(today);
            tomorrow.setDate(today.getDate() + 1);
            
            const sampleEvents = [
                {
                    id: 1,
                    title: 'Team Meeting',
                    date: this.formatDateForInput(today),
                    time: '10:00',
                    description: 'Weekly team sync meeting',
                    color: '#4285f4'
                },
                {
                    id: 2,
                    title: 'Project Deadline',
                    date: this.formatDateForInput(tomorrow),
                    time: '17:00',
                    description: 'Submit final project deliverables',
                    color: '#ea4335'
                },
                {
                    id: 3,
                    title: 'Lunch with Client',
                    date: this.formatDateForInput(today),
                    time: '12:30',
                    description: 'Business lunch at downtown restaurant',
                    color: '#34a853'
                }
            ];
            
            this.events = sampleEvents;
            this.saveEvents();
        }
    }
}

// Initialize the calendar when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new GoogleCalendar();
});

// Add some utility functions for future enhancements
class CalendarUtils {
    static getWeekNumber(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const dayNum = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - dayNum);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    static getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    static getFirstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay();
    }

    static isLeapYear(year) {
        return (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
    }

    static addDays(date, days) {
        const result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
    }

    static addMonths(date, months) {
        const result = new Date(date);
        result.setMonth(result.getMonth() + months);
        return result;
    }

    static formatDateRange(startDate, endDate) {
        const start = new Date(startDate);
        const end = new Date(endDate);
        
        if (start.getTime() === end.getTime()) {
            return start.toLocaleDateString();
        }
        
        return `${start.toLocaleDateString()} - ${end.toLocaleDateString()}`;
    }
}

// Export for potential module use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { GoogleCalendar, CalendarUtils };
}