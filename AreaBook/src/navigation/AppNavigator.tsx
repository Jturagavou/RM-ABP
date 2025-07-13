import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { ActivityIndicator, View } from 'react-native';

import { useAuth } from '../context/AuthContext';
import { RootStackParamList, MainTabParamList, AuthStackParamList } from '../types';

// Auth Screens
import LoginScreen from '../screens/Auth/LoginScreen';
import SignUpScreen from '../screens/Auth/SignUpScreen';
import ForgotPasswordScreen from '../screens/Auth/ForgotPasswordScreen';
import OnboardingScreen from '../screens/Auth/OnboardingScreen';

// Main Screens
import DashboardScreen from '../screens/Dashboard/DashboardScreen';
import GoalsScreen from '../screens/Goals/GoalsScreen';
import CalendarScreen from '../screens/Calendar/CalendarScreen';
import TasksScreen from '../screens/Tasks/TasksScreen';
import NotesScreen from '../screens/Notes/NotesScreen';
import SettingsScreen from '../screens/Settings/SettingsScreen';

const RootStack = createStackNavigator<RootStackParamList>();
const AuthStack = createStackNavigator<AuthStackParamList>();
const MainTab = createBottomTabNavigator<MainTabParamList>();

const AuthNavigator = () => {
  return (
    <AuthStack.Navigator 
      screenOptions={{ 
        headerShown: false,
        cardStyle: { backgroundColor: '#fff' }
      }}
    >
      <AuthStack.Screen name="Login" component={LoginScreen} />
      <AuthStack.Screen name="SignUp" component={SignUpScreen} />
      <AuthStack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
      <AuthStack.Screen name="Onboarding" component={OnboardingScreen} />
    </AuthStack.Navigator>
  );
};

const MainNavigator = () => {
  return (
    <MainTab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap;

          switch (route.name) {
            case 'Dashboard':
              iconName = focused ? 'home' : 'home-outline';
              break;
            case 'Goals':
              iconName = focused ? 'flag' : 'flag-outline';
              break;
            case 'Calendar':
              iconName = focused ? 'calendar' : 'calendar-outline';
              break;
            case 'Tasks':
              iconName = focused ? 'checkbox' : 'checkbox-outline';
              break;
            case 'Notes':
              iconName = focused ? 'document-text' : 'document-text-outline';
              break;
            case 'Settings':
              iconName = focused ? 'settings' : 'settings-outline';
              break;
            default:
              iconName = 'home-outline';
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#3B82F6',
        tabBarInactiveTintColor: '#6B7280',
        tabBarStyle: {
          backgroundColor: '#fff',
          borderTopWidth: 1,
          borderTopColor: '#E5E7EB',
          paddingTop: 5,
        },
        headerStyle: {
          backgroundColor: '#3B82F6',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      })}
    >
      <MainTab.Screen 
        name="Dashboard" 
        component={DashboardScreen}
        options={{ title: 'Dashboard' }}
      />
      <MainTab.Screen 
        name="Goals" 
        component={GoalsScreen}
        options={{ title: 'Goals' }}
      />
      <MainTab.Screen 
        name="Calendar" 
        component={CalendarScreen}
        options={{ title: 'Calendar' }}
      />
      <MainTab.Screen 
        name="Tasks" 
        component={TasksScreen}
        options={{ title: 'Tasks' }}
      />
      <MainTab.Screen 
        name="Notes" 
        component={NotesScreen}
        options={{ title: 'Notes' }}
      />
      <MainTab.Screen 
        name="Settings" 
        component={SettingsScreen}
        options={{ title: 'Settings' }}
      />
    </MainTab.Navigator>
  );
};

const AppNavigator = () => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color="#3B82F6" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <RootStack.Navigator screenOptions={{ headerShown: false }}>
        {user ? (
          <RootStack.Screen name="Main" component={MainNavigator} />
        ) : (
          <RootStack.Screen name="Auth" component={AuthNavigator} />
        )}
      </RootStack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;