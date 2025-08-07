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
    
    init() {
        loadRoutines()
    }
    
    func saveRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
        } else {
            routines.append(routine)
        }
        saveToUserDefaults()
    }
    
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveToUserDefaults()
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
