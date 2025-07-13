import React, { createContext, useContext, useEffect, useState } from 'react';
import { 
  User as FirebaseUser, 
  onAuthStateChanged, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut,
  sendPasswordResetEmail
} from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { auth, db } from '../services/firebase';
import { User } from '../types';

interface AuthContextType {
  user: User | null;
  firebaseUser: FirebaseUser | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, name: string) => Promise<void>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      setFirebaseUser(firebaseUser);
      
      if (firebaseUser) {
        // Fetch user data from Firestore
        const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid));
        if (userDoc.exists()) {
          const userData = userDoc.data();
          setUser({
            id: firebaseUser.uid,
            email: firebaseUser.email!,
            name: userData.name,
            avatar: userData.avatar,
            createdAt: userData.createdAt?.toDate() || new Date(),
            lastSeen: new Date(),
            settings: userData.settings || {
              defaultCalendarView: 'monthly',
              defaultTaskView: 'day',
              eventColorScheme: {},
              notificationsEnabled: true,
              pushNotifications: true,
            }
          });
        }
      } else {
        setUser(null);
      }
      
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const signIn = async (email: string, password: string) => {
    setLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (error) {
      setLoading(false);
      throw error;
    }
  };

  const signUp = async (email: string, password: string, name: string) => {
    setLoading(true);
    try {
      const result = await createUserWithEmailAndPassword(auth, email, password);
      
      // Create user document in Firestore
      const userData: Omit<User, 'id' | 'lastSeen'> = {
        email,
        name,
        createdAt: new Date(),
        settings: {
          defaultCalendarView: 'monthly',
          defaultTaskView: 'day',
          eventColorScheme: {
            'Church': '#3B82F6',
            'School': '#10B981',
            'Personal': '#8B5CF6',
            'Work': '#F59E0B'
          },
          notificationsEnabled: true,
          pushNotifications: true,
        }
      };
      
      await setDoc(doc(db, 'users', result.user.uid), userData);
    } catch (error) {
      setLoading(false);
      throw error;
    }
  };

  const logout = async () => {
    await signOut(auth);
  };

  const resetPassword = async (email: string) => {
    await sendPasswordResetEmail(auth, email);
  };

  const value: AuthContextType = {
    user,
    firebaseUser,
    loading,
    signIn,
    signUp,
    logout,
    resetPassword
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};