//
//  RoutineStorage.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Routine Storage Manager
class RoutineStorage: ObservableObject {
    @Published var routines: [Routine] = []
    private let userDefaults = UserDefaults.standard
    private let firebaseService = FirebaseService.shared
    
    init() {
        // Don't load routines immediately - wait for authentication state
        setupAuthStateListener()
        clearOldGlobalData()
    }
    
    private func setupAuthStateListener() {
        // Listen to authentication state changes
        firebaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    // User logged in - load their routines from Firebase
                    self?.loadRoutinesFromFirebase()
                } else {
                    // User logged out - clear local routines
                    DispatchQueue.main.async {
                        self?.routines = []
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // Clear old global UserDefaults data
    private func clearOldGlobalData() {
        // Remove old global keys that might still exist
        userDefaults.removeObject(forKey: "savedRoutines")
        print("Cleared old global routines data")
    }
    
    func saveRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
        } else {
            routines.append(routine)
        }
        
        // Save to UserDefaults for offline access (user-specific)
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
                print("Routines loaded from Firebase successfully: \(firebaseRoutines.count) routines")
            } catch {
                print("Error loading routines from Firebase: \(error)")
                // Fall back to UserDefaults if Firebase fails
                await MainActor.run {
                    self.loadRoutinesFromUserDefaults()
                }
            }
        }
    }
    
    func syncLocalRoutinesToFirebase() {
        guard firebaseService.isAuthenticated else { return }
        
        // Load local routines first
        loadRoutinesFromUserDefaults()
        
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
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "savedRoutines_\(userId)"
        if let encoded = try? JSONEncoder().encode(routines) {
            userDefaults.set(encoded, forKey: userSpecificKey)
            print("Saved \(routines.count) routines to UserDefaults for user: \(userId)")
        }
    }
    
    private func loadRoutinesFromUserDefaults() {
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        let userSpecificKey = "savedRoutines_\(userId)"
        if let data = userDefaults.data(forKey: userSpecificKey),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
            print("Loaded \(routines.count) routines from UserDefaults for user: \(userId)")
        } else {
            routines = []
            print("No routines found in UserDefaults for user: \(userId)")
        }
    }
}
