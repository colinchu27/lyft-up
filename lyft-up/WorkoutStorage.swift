//
//  WorkoutStorage.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import SwiftUI

// MARK: - Workout Storage Manager
class WorkoutStorage: ObservableObject {
    @Published var workouts: [Workout] = []
    private let userDefaults = UserDefaults.standard
    private let workoutsKey = "savedWorkouts"
    
    init() {
        loadWorkouts()
    }
    
    func saveWorkout(_ workout: Workout) {
        workouts.append(workout)
        saveToUserDefaults()
    }
    
    func getLastWorkout(for exerciseName: String) -> Workout? {
        return workouts
            .filter { $0.exerciseName.lowercased() == exerciseName.lowercased() }
            .sorted { $0.date > $1.date }
            .first
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: workoutsKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = userDefaults.data(forKey: workoutsKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
    }
}
