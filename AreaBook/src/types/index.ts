export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  createdAt: Date;
  lastSeen: Date;
  settings: UserSettings;
}

export interface UserSettings {
  defaultCalendarView: 'monthly' | 'weekly';
  defaultTaskView: 'day' | 'week' | 'goal';
  eventColorScheme: Record<string, string>;
  notificationsEnabled: boolean;
  pushNotifications: boolean;
  dailyKIReviewTime?: string;
}

export interface KeyIndicator {
  id: string;
  name: string;
  weeklyTarget: number;
  currentWeekProgress: number;
  unit: string;
  color: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Goal {
  id: string;
  title: string;
  description: string;
  keyIndicatorIds: string[];
  progress: number; // 0-100
  status: 'active' | 'completed' | 'paused' | 'cancelled';
  targetDate?: Date;
  createdAt: Date;
  updatedAt: Date;
  linkedNoteIds: string[];
  stickyNotes: StickyNote[];
}

export interface StickyNote {
  id: string;
  content: string;
  color: string;
  position: { x: number; y: number };
  createdAt: Date;
}

export interface CalendarEvent {
  id: string;
  title: string;
  description: string;
  category: string;
  startTime: Date;
  endTime: Date;
  linkedGoalId?: string;
  taskIds: string[];
  isRecurring: boolean;
  recurrencePattern?: RecurrencePattern;
  status: 'scheduled' | 'completed' | 'cancelled';
  createdAt: Date;
  updatedAt: Date;
}

export interface RecurrencePattern {
  type: 'daily' | 'weekly' | 'monthly' | 'yearly';
  interval: number;
  daysOfWeek?: number[]; // 0-6, Sunday = 0
  endDate?: Date;
}

export interface Task {
  id: string;
  title: string;
  description?: string;
  status: 'pending' | 'completed' | 'failed' | 'skipped';
  priority: 'low' | 'medium' | 'high';
  dueDate?: Date;
  linkedGoalId?: string;
  linkedEventId?: string;
  subtasks: Subtask[];
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;
}

export interface Subtask {
  id: string;
  title: string;
  completed: boolean;
  createdAt: Date;
}

export interface Note {
  id: string;
  title: string;
  content: string; // Markdown content
  tags: string[];
  linkedNoteIds: string[];
  linkedGoalIds: string[];
  linkedTaskIds: string[];
  linkedEventIds: string[];
  folder?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface AccountabilityGroup {
  id: string;
  name: string;
  type: 'district' | 'companionship';
  parentGroupId?: string; // For companionships within districts
  members: GroupMember[];
  createdAt: Date;
  updatedAt: Date;
}

export interface GroupMember {
  userId: string;
  role: 'admin' | 'leader' | 'member' | 'viewer';
  joinedAt: Date;
  permissions: GroupPermissions;
}

export interface GroupPermissions {
  canViewGoals: boolean;
  canViewEvents: boolean;
  canViewTasks: boolean;
  canViewKIs: boolean;
  canSendEncouragements: boolean;
  canManageMembers: boolean;
}

export interface Encouragement {
  id: string;
  fromUserId: string;
  toUserId: string;
  message: string;
  type: 'encouragement' | 'nudge' | 'congratulations';
  sentAt: Date;
  readAt?: Date;
}

export interface DashboardData {
  weeklyKIs: KeyIndicator[];
  todaysTasks: Task[];
  todaysEvents: CalendarEvent[];
  quote: DailyQuote;
  recentGoals: Goal[];
}

export interface DailyQuote {
  text: string;
  author: string;
  source?: string;
}

// Navigation types
export type RootStackParamList = {
  Auth: undefined;
  Main: undefined;
};

export type MainTabParamList = {
  Dashboard: undefined;
  Goals: undefined;
  Calendar: undefined;
  Tasks: undefined;
  Notes: undefined;
  Settings: undefined;
};

export type AuthStackParamList = {
  Login: undefined;
  SignUp: undefined;
  ForgotPassword: undefined;
  Onboarding: undefined;
};

// Form types
export interface CreateGoalForm {
  title: string;
  description: string;
  keyIndicatorIds: string[];
  targetDate?: Date;
}

export interface CreateEventForm {
  title: string;
  description: string;
  category: string;
  startTime: Date;
  endTime: Date;
  linkedGoalId?: string;
  isRecurring: boolean;
  recurrencePattern?: RecurrencePattern;
}

export interface CreateTaskForm {
  title: string;
  description?: string;
  priority: 'low' | 'medium' | 'high';
  dueDate?: Date;
  linkedGoalId?: string;
  linkedEventId?: string;
}

export interface CreateNoteForm {
  title: string;
  content: string;
  tags: string[];
  folder?: string;
}

export interface CreateKIForm {
  name: string;
  weeklyTarget: number;
  unit: string;
  color: string;
}