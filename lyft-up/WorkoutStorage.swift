//
//  WorkoutStorage.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Workout Storage Manager
class WorkoutStorage: ObservableObject {
    @Published var workouts: [Workout] = []
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
                    // User logged in - load their workouts from UserDefaults
                    self?.loadWorkoutsFromUserDefaults()
                } else {
                    // User logged out - clear local workouts
                    DispatchQueue.main.async {
                        self?.workouts = []
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Clear old global UserDefaults data
    private func clearOldGlobalData() {
        // Remove old global keys that might still exist
        userDefaults.removeObject(forKey: "savedWorkouts")
        print("Cleared old global workouts data")
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
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "savedWorkouts_\(userId)"
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: userSpecificKey)
            print("Saved \(workouts.count) workouts to UserDefaults for user: \(userId)")
        }
    }
    
    private func loadWorkoutsFromUserDefaults() {
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "savedWorkouts_\(userId)"
        if let data = userDefaults.data(forKey: userSpecificKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
            print("Loaded \(workouts.count) workouts from UserDefaults for user: \(userId)")
        } else {
            workouts = []
            print("No workouts found in UserDefaults for user: \(userId)")
        }
    }
}
