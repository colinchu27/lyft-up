//
//  FirebaseUserService.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirebaseUserService {
    private let db = Firestore.firestore()
    
    // MARK: - Username Management
    
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        do {
            let document = try await db.collection("usernames").document(username).getDocument()
            return !document.exists
        } catch {
            print("Error checking username availability: \(error)")
            throw error
        }
    }
    
    func getUserByUsername(_ username: String) async throws -> UserProfile? {
        do {
            let document = try await db.collection("usernames").document(username).getDocument()
            guard document.exists,
                  let data = document.data(),
                  let userId = data["userId"] as? String else {
                return nil
            }
            
            return try await loadUserProfileById(userId)
        } catch {
            print("Error getting user by username: \(error)")
            throw error
        }
    }
    
    func loadUserProfileById(_ userId: String) async throws -> UserProfile? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            guard let data = document.data() else { 
                return nil 
            }
            
            return try FirebaseDataConverter.dictionaryToUserProfile(data)
        } catch {
            print("Error loading user profile by ID: \(error)")
            throw error
        }
    }
    
    // MARK: - User Profile
    
    func saveUserProfile(_ userProfile: UserProfile) async throws {
        do {
            let userData = try FirebaseDataConverter.userProfileToDictionary(userProfile)
            try await db.collection("users").document(userProfile.id)
                .setData(userData)
            
            // Also create a username index for easy lookup
            try await db.collection("usernames").document(userProfile.username)
                .setData([
                    "userId": userProfile.id,
                    "createdAt": userProfile.createdAt.timeIntervalSince1970
                ])
            
            print("User profile saved successfully")
        } catch {
            print("Error saving user profile: \(error)")
            throw error
        }
    }
    
    func loadUserProfile(userId: String) async throws -> UserProfile? {
        do {
            print("Loading user profile")
            let document = try await db.collection("users").document(userId).getDocument()
            guard let data = document.data() else { 
                print("No user profile found")
                return nil 
            }
            
            let profile = try FirebaseDataConverter.dictionaryToUserProfile(data)
            print("Successfully loaded user profile: \(profile.username)")
            return profile
        } catch {
            print("Error loading user profile: \(error)")
            throw error
        }
    }
    
    // MARK: - Profile Management
    
    func isProfileComplete(_ profile: UserProfile) -> Bool {
        // For now, just check if username exists - make it more lenient
        let isComplete = !profile.username.isEmpty
        print("Profile completeness check - Username: '\(profile.username)', IsComplete: \(isComplete)")
        return isComplete
    }
    
    // MARK: - Stats Recalculation
    
    func recalculateAndUpdateUserStats(userId: String, userProfile: UserProfile, loadWorkoutSessions: @escaping (String) async throws -> [WorkoutSession]) async throws -> UserProfile {
        print("🔄 Recalculating user stats for user: \(userId)")
        
        do {
            // Load all workout sessions from Firebase
            let sessions = try await loadWorkoutSessions(userId)
            let completedSessions = sessions.filter { $0.isCompleted }
            
            print("📊 Found \(completedSessions.count) completed sessions out of \(sessions.count) total sessions")
            
            // Calculate total workouts and weight
            let totalWorkouts = completedSessions.count
            let totalWeightLifted = completedSessions.reduce(0.0) { total, session in
                total + session.exercises.reduce(0.0) { exerciseTotal, exercise in
                    exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                        setTotal + (set.weight * Double(set.reps))
                    }
                }
            }
            let lastWorkoutDate = completedSessions.max(by: { $0.startTime < $1.startTime })?.startTime
            
            print("📈 Calculated stats: \(totalWorkouts) workouts, \(totalWeightLifted) lbs")
            
            // Update user profile with correct stats
            var updatedProfile = userProfile
            updatedProfile.totalWorkouts = totalWorkouts
            updatedProfile.totalWeightLifted = totalWeightLifted
            updatedProfile.lastWorkoutDate = lastWorkoutDate
            
            try await saveUserProfile(updatedProfile)
            
            print("✅ Successfully updated user profile with correct stats")
            print("   - Total Workouts: \(totalWorkouts)")
            print("   - Total Weight: \(totalWeightLifted) lbs")
            print("   - Last Workout: \(lastWorkoutDate?.formatted() ?? "None")")
            
            return updatedProfile
        } catch {
            print("❌ Error recalculating user stats: \(error)")
            throw error
        }
    }
}
