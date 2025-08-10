//
//  RoutineStorage.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import SwiftUI

// MARK: - Routine Storage Manager
class RoutineStorage: ObservableObject {
    @Published var routines: [Routine] = []
    private let userDefaults = UserDefaults.standard
    private let routinesKey = "savedRoutines"
    private let firebaseService = FirebaseService.shared
    
    init() {
        loadRoutines()
    }
    
    func saveRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
        } else {
            routines.append(routine)
        }
        
        // Save to UserDefaults for offline access
        saveToUserDefaults()
        
        // Save to Firebase if user is authenticated
        if firebaseService.isAuthenticated {
            Task {
                do {
                    try await firebaseService.saveRoutine(routine)
                    print("Routine saved to Firebase successfully")
                } catch {
                    print("Error saving routine to Firebase: \(error)")
                }
            }
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveToUserDefaults()
        
        // Delete from Firebase if user is authenticated
        if firebaseService.isAuthenticated {
            Task {
                do {
                    try await firebaseService.deleteRoutine(routine)
                    print("Routine deleted from Firebase successfully")
                } catch {
                    print("Error deleting routine from Firebase: \(error)")
                }
            }
        }
    }
    
    func loadRoutinesFromFirebase() {
        guard firebaseService.isAuthenticated else { return }
        
        Task {
            do {
                let firebaseRoutines = try await firebaseService.loadRoutines()
                await MainActor.run {
                    self.routines = firebaseRoutines
                    // Also save to UserDefaults for offline access
                    self.saveToUserDefaults()
                }
                print("Routines loaded from Firebase successfully")
            } catch {
                print("Error loading routines from Firebase: \(error)")
                // Fall back to UserDefaults if Firebase fails
                await MainActor.run {
                    self.loadRoutines()
                }
            }
        }
    }
    
    func syncLocalRoutinesToFirebase() {
        guard firebaseService.isAuthenticated else { return }
        
        // Load local routines first
        loadRoutines()
        
        // Upload each local routine to Firebase
        for routine in routines {
            Task {
                do {
                    try await firebaseService.saveRoutine(routine)
                    print("Synced local routine '\(routine.name)' to Firebase")
                } catch {
                    print("Error syncing routine '\(routine.name)' to Firebase: \(error)")
                }
            }
        }
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(routines) {
            userDefaults.set(encoded, forKey: routinesKey)
        }
    }
    
    private func loadRoutines() {
        if let data = userDefaults.data(forKey: routinesKey),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
        }
    }
}
