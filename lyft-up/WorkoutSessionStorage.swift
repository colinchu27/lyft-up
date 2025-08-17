//
//  WorkoutSessionStorage.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Workout Statistics Storage Manager
class WorkoutStatsStorage: ObservableObject {
    static let shared = WorkoutStatsStorage()
    
    @Published var stats: WorkoutStats
    private let userDefaults = UserDefaults.standard
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.stats = WorkoutStats()
        setupAuthStateListener()
        clearOldGlobalData()
    }
    
    private func setupAuthStateListener() {
        // Listen to authentication state changes
        firebaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    // User logged in - load their stats from Firebase
                    self?.loadFromFirebase()
                } else {
                    // User logged out - clear local stats
                    DispatchQueue.main.async {
                        self?.stats = WorkoutStats()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Clear old global UserDefaults data
    private func clearOldGlobalData() {
        // Remove old global keys that might still exist
        userDefaults.removeObject(forKey: "workoutStats")
        print("Cleared old global workout stats data")
    }
    
    func incrementTotalWorkouts() {
        // Instead of incrementing a counter, recalculate from actual sessions
        recalculateStatsFromSessions()
    }
    
    func addWeightLifted(_ weight: Double) {
        // Instead of adding to a counter, recalculate from actual sessions
        recalculateStatsFromSessions()
    }
    
    func getTotalWorkouts() -> Int {
        // Always calculate from actual sessions
        let completedSessions = WorkoutSessionStorage.shared.sessions.filter { $0.isCompleted }
        return completedSessions.count
    }
    
    private func saveStats() {
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "workoutStats_\(userId)"
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: userSpecificKey)
            print("Saved workout stats to UserDefaults for user: \(userId)")
        }
    }
    
    private func loadStats() {
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "workoutStats_\(userId)"
        if let data = userDefaults.data(forKey: userSpecificKey),
           let decoded = try? JSONDecoder().decode(WorkoutStats.self, from: data) {
            stats = decoded
            print("Loaded workout stats from UserDefaults for user: \(userId)")
        } else {
            stats = WorkoutStats()
            print("No workout stats found in UserDefaults for user: \(userId)")
        }
    }
    
    private func syncToFirebase() {
        Task {
            do {
                if var userProfile = firebaseService.userProfile {
                    // Always calculate stats from actual sessions
                    let completedSessions = WorkoutSessionStorage.shared.sessions.filter { $0.isCompleted }
                    let totalWorkouts = completedSessions.count
                    let totalWeightLifted = completedSessions.reduce(0.0) { total, session in
                        total + session.exercises.reduce(0.0) { exerciseTotal, exercise in
                            exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                                setTotal + (set.weight * Double(set.reps))
                            }
                        }
                    }
                    let lastWorkoutDate = completedSessions.max(by: { $0.startTime < $1.startTime })?.startTime
                    
                    userProfile.totalWorkouts = totalWorkouts
                    userProfile.totalWeightLifted = totalWeightLifted
                    userProfile.lastWorkoutDate = lastWorkoutDate
                    
                    print("Syncing to Firebase - Workouts: \(totalWorkouts), Weight: \(totalWeightLifted) lbs")
                    
                    try await firebaseService.saveUserProfile(userProfile)
                    
                    await MainActor.run {
                        firebaseService.userProfile = userProfile
                    }
                }
            } catch {
                print("Error syncing workout stats to Firebase: \(error)")
            }
        }
    }
    
    // Load stats from Firebase user profile
    func loadFromFirebase() {
        // Always recalculate from actual sessions instead of trusting stored values
        recalculateStatsFromSessions()
    }
    
    // Recalculate stats from actual workout sessions to ensure consistency
    func recalculateStatsFromSessions() {
        Task {
            await recalculateStatsFromSessionsAsync()
        }
    }
    
    private func recalculateStatsFromSessionsAsync() async {
        // First, ensure sessions are loaded from Firebase
        await WorkoutSessionStorage.shared.loadSessionsFromFirebaseAsync()
        
        let completedSessions = WorkoutSessionStorage.shared.sessions.filter { $0.isCompleted }
        
        print("Recalculating stats - Found \(completedSessions.count) completed sessions out of \(WorkoutSessionStorage.shared.sessions.count) total sessions")
        
        let newTotalWorkouts = completedSessions.count
        let newTotalWeight = completedSessions.reduce(0.0) { total, session in
            total + session.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
            }
        }
        let newLastWorkoutDate = completedSessions.max(by: { $0.startTime < $1.startTime })?.startTime
        
        await MainActor.run {
            stats.totalWorkouts = newTotalWorkouts
            stats.totalWeightLifted = newTotalWeight
            stats.lastWorkoutDate = newLastWorkoutDate
            
            print("Recalculated stats: \(stats.totalWorkouts) workouts, \(stats.totalWeightLifted) lbs")
            
            saveStats()
            // Force sync to Firebase to ensure consistency
            syncToFirebase()
        }
    }
}

// MARK: - Workout Session Storage Manager
class WorkoutSessionStorage: ObservableObject {
    static let shared = WorkoutSessionStorage()
    
    @Published var sessions: [WorkoutSession] = []
    private let userDefaults = UserDefaults.standard
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
        clearOldGlobalData()
    }
    
    private func setupAuthStateListener() {
        // Listen to authentication state changes
        firebaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    // User logged in - load their sessions from Firebase
                    self?.loadSessionsFromFirebase()
                } else {
                    // User logged out - clear local sessions
                    DispatchQueue.main.async {
                        self?.sessions = []
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Clear old global UserDefaults data
    private func clearOldGlobalData() {
        // Remove old global keys that might still exist
        userDefaults.removeObject(forKey: "savedWorkoutSessions")
        print("Cleared old global workout sessions data")
    }
    
    func saveSession(_ session: WorkoutSession) {
        print("WorkoutSessionStorage: Saving session '\(session.routineName)' with \(session.exercises.count) exercises")
        print("WorkoutSessionStorage: Session completed: \(session.isCompleted)")
        
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            print("WorkoutSessionStorage: Updated existing session")
        } else {
            sessions.append(session)
            print("WorkoutSessionStorage: Added new session")
        }
        
        print("WorkoutSessionStorage: Total sessions now: \(sessions.count)")
        print("WorkoutSessionStorage: Completed sessions: \(sessions.filter { $0.isCompleted }.count)")
        
        // Save to UserDefaults for offline access (user-specific)
        saveToUserDefaults()
        
        // Save to Firebase if user is authenticated
        if firebaseService.isAuthenticated {
            Task {
                do {
                    try await firebaseService.saveWorkoutSession(session)
                    print("Workout session saved to Firebase successfully")
                    print("Firebase save - Session: \(session.routineName), Completed: \(session.isCompleted), ID: \(session.id)")
                    
                    // Wait a moment for Firebase consistency, then reload sessions
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await loadSessionsFromFirebaseAsync()
                    
                    // Trigger stats recalculation after saving session
                    WorkoutStatsStorage.shared.recalculateStatsFromSessions()
                } catch {
                    print("Error saving workout session to Firebase: \(error)")
                }
            }
        }
    }
    
    func deleteSession(_ session: WorkoutSession) {
        sessions.removeAll { $0.id == session.id }
        saveToUserDefaults()
        
        // Delete from Firebase if user is authenticated
        if firebaseService.isAuthenticated {
            Task {
                do {
                    try await firebaseService.deleteWorkoutSession(session)
                    print("Workout session deleted from Firebase successfully")
                } catch {
                    print("Error deleting workout session from Firebase: \(error)")
                }
            }
        }
    }
    
    func loadSessionsFromFirebase() {
        guard firebaseService.isAuthenticated else { return }
        
        Task {
            await loadSessionsFromFirebaseAsync()
        }
    }
    
    func loadSessionsFromFirebaseAsync() async {
        guard firebaseService.isAuthenticated else { return }
        
        do {
            let firebaseSessions = try await firebaseService.loadWorkoutSessions()
            await MainActor.run {
                self.sessions = firebaseSessions
                // Also save to UserDefaults for offline access
                self.saveToUserDefaults()
            }
            print("Workout sessions loaded from Firebase successfully: \(firebaseSessions.count) sessions")
            print("Firebase load - Sessions: \(firebaseSessions.map { "\($0.routineName) - \($0.isCompleted)" })")
        } catch {
            print("Error loading workout sessions from Firebase: \(error)")
            // Fall back to UserDefaults if Firebase fails
            await MainActor.run {
                self.loadSessionsFromUserDefaults()
            }
        }
    }
    
    func syncLocalSessionsToFirebase() {
        guard firebaseService.isAuthenticated else { return }
        
        // Load local sessions first
        loadSessionsFromUserDefaults()
        
        // Upload each local session to Firebase
        for session in sessions {
            Task {
                do {
                    try await firebaseService.saveWorkoutSession(session)
                    print("Synced local workout session '\(session.routineName)' to Firebase")
                } catch {
                    print("Error syncing workout session '\(session.routineName)' to Firebase: \(error)")
                }
            }
        }
    }
    
    func getLastWorkoutData(for exerciseName: String) -> (weight: Double, reps: Int)? {
        // Get the most recent workout data for this exercise
        let allWorkouts = sessions.flatMap { session in
            session.exercises.flatMap { exercise in
                exercise.sets.map { set in
                    (exerciseName: exercise.exerciseName, weight: set.weight, reps: set.reps, date: session.startTime)
                }
            }
        }
        
        let exerciseWorkouts = allWorkouts.filter { $0.exerciseName.lowercased() == exerciseName.lowercased() }
        let sortedWorkouts = exerciseWorkouts.sorted { $0.date > $1.date }
        
        guard let lastWorkout = sortedWorkouts.first else { return nil }
        return (weight: lastWorkout.weight, reps: lastWorkout.reps)
    }
    
    private func saveToUserDefaults() {
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "savedWorkoutSessions_\(userId)"
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: userSpecificKey)
            print("Saved \(sessions.count) workout sessions to UserDefaults for user: \(userId)")
        }
    }
    
    private func loadSessionsFromUserDefaults() {
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "savedWorkoutSessions_\(userId)"
        if let data = userDefaults.data(forKey: userSpecificKey),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            sessions = decoded
            print("Loaded \(sessions.count) workout sessions from UserDefaults for user: \(userId)")
        } else {
            sessions = []
            print("No workout sessions found in UserDefaults for user: \(userId)")
        }
    }
}
