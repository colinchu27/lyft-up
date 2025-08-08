# Lyft-Up 🚀  (In Progress)
**Track your lifts. Follow your friends. Stay accountable.**

---

## 📱 What is Lyft-Up?

Lyft-Up is an iOS app that combines clean workout tracking with social features to help you and your friends stay consistent and motivated in the gym.

Inspired by apps like **RepCount**, Lyft-Up lets you build your own routines, log sets/reps/weights, and automatically reference your last performance to push yourself further, but with a twist:  
👥 You can follow friends, see their workout history, and share your own progress!

This is my **first iOS app** built from scratch using SwiftUI. It's a personal project meant to solve a real user need I’ve experienced: making workouts more interactive, social, and accountable, without the bloat or distractions of other fitness apps.

---

## 🔧 Core Features (So Far)

✅ Create custom workout routines  
✅ Log sets, reps, and weights  
✅ View past performance during workouts  
✅ Auto-load last session data for each exercise  
✅ Designed for fast, intuitive gym use

---

## 💡 Why I’m Building This

Most gym apps either feel too bloated or too isolated. They don’t help you stay consistent, and they don’t let you connect with the people you train with. Lyft-Up was born from the idea that:

- Progress is more fun when shared  
- Accountability boosts consistency  
- Gym apps should be fast, clear, and motivating  

---

## 🧱 Tech Stack

- SwiftUI (UI)
- Xcode
- MVVM architecture (as project scales)
- Firebase (Authentication & Firestore)
- Local data persistence (UserDefaults)
- iOS Simulator for dev/testing

## 🔐 Security & Setup

### Firebase Configuration
This app uses Firebase for authentication and data storage. To set up the project:

1. **Download your Firebase config file:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select existing one
   - Add an iOS app with your bundle ID
   - Download `GoogleService-Info.plist`

2. **Add the config file to your project:**
   - Place `GoogleService-Info.plist` in the `lyft-up/` directory
   - **IMPORTANT:** This file contains sensitive API keys and should never be committed to version control
   - The file is already added to `.gitignore` to prevent accidental commits

3. **Enable Authentication:**
   - In Firebase Console, go to Authentication > Sign-in method
   - Enable Email/Password authentication

### Security Notes
- ✅ No sensitive data is logged to console
- ✅ API keys are properly excluded from version control
- ✅ User passwords are handled securely through Firebase Auth
- ✅ All user data is stored in Firebase Firestore with proper authentication

### Development Setup
1. Clone the repository
2. Add your `GoogleService-Info.plist` file
3. Build and run in Xcode



