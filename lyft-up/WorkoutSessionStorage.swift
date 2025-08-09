//
//  WorkoutSessionStorage.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import SwiftUI

// MARK: - Workout Statistics Storage Manager
class WorkoutStatsStorage: ObservableObject {
    static let shared = WorkoutStatsStorage()
    
    @Published var stats: WorkoutStats
    private let userDefaults = UserDefaults.standard
    private let statsKey = "workoutStats"
    
    init() {
        self.stats = WorkoutStats()
        loadStats()
    }
    
    func incrementTotalWorkouts() {
        stats.totalWorkouts += 1
        stats.lastWorkoutDate = Date()
        saveStats()
    }
    
    func getTotalWorkouts() -> Int {
        return stats.totalWorkouts
    }
    
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: statsKey)
        }
    }
    
    private func loadStats() {
        if let data = userDefaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(WorkoutStats.self, from: data) {
            stats = decoded
        }
    }
}

// MARK: - Workout Session Storage Manager
class WorkoutSessionStorage: ObservableObject {
    @Published var sessions: [WorkoutSession] = []
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "savedWorkoutSessions"
    
    init() {
        loadSessions()
    }
    
    func saveSession(_ session: WorkoutSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        saveToUserDefaults()
    }
    
    func deleteSession(_ session: WorkoutSession) {
        sessions.removeAll { $0.id == session.id }
        saveToUserDefaults()
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
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            sessions = decoded
        }
    }
}
