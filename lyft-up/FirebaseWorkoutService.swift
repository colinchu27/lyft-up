//
//  FirebaseWorkoutService.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirebaseWorkoutService {
    private let db = Firestore.firestore()
    
    // MARK: - Workout Sessions
    
    func saveWorkoutSession(_ session: WorkoutSession, userId: String) async throws {
        do {
            let sessionData = try FirebaseDataConverter.sessionToDictionary(session)
            let path = "users/\(userId)/workoutSessions/\(session.id.uuidString)"
            try await db.collection("users").document(userId)
                .collection("workoutSessions")
                .document(session.id.uuidString)
                .setData(sessionData)
            
            print("✅ Workout session '\(session.routineName)' saved successfully to: \(path)")
        } catch {
            print("❌ Error saving workout session '\(session.routineName)': \(error)")
            throw error
        }
    }
    
    func loadWorkoutSessionsForUser(_ userId: String) async throws -> [WorkoutSession] {
        do {
            let path = "users/\(userId)/workoutSessions"
            let snapshot = try await db.collection("users").document(userId)
                .collection("workoutSessions")
                .order(by: "startTime", descending: true)
                .getDocuments()
            
            let sessions = try snapshot.documents.compactMap { document in
                try FirebaseDataConverter.dictionaryToSession(document.data())
            }
            
            print("💪 Loaded \(sessions.count) workout sessions for user \(userId) from: \(path)")
            for session in sessions {
                print("   - \(session.routineName) (\(session.startTime.formatted()))")
            }
            return sessions
        } catch {
            print("❌ Error loading workout sessions for user \(userId): \(error)")
            throw error
        }
    }
    
    func deleteWorkoutSession(_ session: WorkoutSession, userId: String) async throws {
        do {
            try await db.collection("users").document(userId)
                .collection("workoutSessions")
                .document(session.id.uuidString)
                .delete()
            
            print("Workout session deleted successfully")
        } catch {
            print("Error deleting workout session: \(error)")
            throw error
        }
    }
    
    // MARK: - Routines
    
    func saveRoutine(_ routine: Routine, userId: String) async throws {
        do {
            let routineData = try FirebaseDataConverter.routineToDictionary(routine)
            let path = "users/\(userId)/routines/\(routine.id.uuidString)"
            try await db.collection("users").document(userId)
                .collection("routines")
                .document(routine.id.uuidString)
                .setData(routineData)
            
            print("✅ Routine '\(routine.name)' saved successfully to: \(path)")
        } catch {
            print("❌ Error saving routine '\(routine.name)': \(error)")
            throw error
        }
    }
    
    func loadRoutinesForUser(_ userId: String) async throws -> [Routine] {
        do {
            let path = "users/\(userId)/routines"
            let snapshot = try await db.collection("users").document(userId)
                .collection("routines")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let routines = try snapshot.documents.compactMap { document in
                try FirebaseDataConverter.dictionaryToRoutine(document.data())
            }
            
            print("📋 Loaded \(routines.count) routines for user \(userId) from: \(path)")
            for routine in routines {
                print("   - \(routine.name)")
            }
            return routines
        } catch {
            print("❌ Error loading routines for user \(userId): \(error)")
            throw error
        }
    }
    
    func deleteRoutine(_ routine: Routine, userId: String) async throws {
        do {
            try await db.collection("users").document(userId)
                .collection("routines")
                .document(routine.id.uuidString)
                .delete()
            
            print("Routine deleted successfully")
        } catch {
            print("Error deleting routine: \(error)")
            throw error
        }
    }
}
