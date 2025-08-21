//
//  FirebaseDataConverter.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation

struct FirebaseDataConverter {
    
    // MARK: - Session Conversion
    
    static func sessionToDictionary(_ session: WorkoutSession) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(session)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        return dictionary
    }
    
    static func dictionaryToSession(_ data: [String: Any]) throws -> WorkoutSession {
        // Extract values from Firestore data, handling potential FIRDocumentReference objects
        guard let id = data["id"] as? String,
              let routineName = data["routineName"] as? String,
              let startTimeTimestamp = data["startTime"] as? TimeInterval,
              let exercisesData = data["exercises"] as? [[String: Any]] else {
            throw FirebaseError.invalidData
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeTimestamp)
        let endTime = (data["endTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        let isCompleted = data["isCompleted"] as? Bool ?? false
        
        var exercises: [WorkoutSessionExercise] = []
        for exerciseData in exercisesData {
            if let exercise = try? dictionaryToSessionExercise(exerciseData) {
                exercises.append(exercise)
            }
        }
        
        var session = WorkoutSession(routineName: routineName)
        session.id = UUID(uuidString: id) ?? UUID()
        session.exercises = exercises
        session.startTime = startTime
        session.endTime = endTime
        session.isCompleted = isCompleted
        
        return session
    }
    
    // MARK: - Routine Conversion
    
    static func routineToDictionary(_ routine: Routine) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(routine)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        return dictionary
    }
    
    static func dictionaryToRoutine(_ data: [String: Any]) throws -> Routine {
        // Extract values from Firestore data, handling potential FIRDocumentReference objects
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let exercisesData = data["exercises"] as? [[String: Any]],
              let createdAtTimestamp = data["createdAt"] as? TimeInterval else {
            throw FirebaseError.invalidData
        }
        
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        
        var exercises: [RoutineExercise] = []
        for exerciseData in exercisesData {
            if let exercise = try? dictionaryToRoutineExercise(exerciseData) {
                exercises.append(exercise)
            }
        }
        
        var routine = Routine(name: name)
        routine.id = UUID(uuidString: id) ?? UUID()
        routine.exercises = exercises
        routine.createdAt = createdAt
        
        return routine
    }
    
    // MARK: - User Profile Conversion
    
    static func userProfileToDictionary(_ userProfile: UserProfile) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(userProfile)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        return dictionary
    }
    
    static func dictionaryToUserProfile(_ data: [String: Any]) throws -> UserProfile {
        // Extract values from Firestore data, handling potential FIRDocumentReference objects
        guard let id = data["id"] as? String,
              let username = data["username"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let bio = data["bio"] as? String,
              let createdAtTimestamp = data["createdAt"] as? TimeInterval else {
            throw FirebaseError.invalidData
        }
        
        let friendIds = data["friendIds"] as? [String] ?? []
        let fitnessGoal = data["fitnessGoal"] as? String ?? ""
        let isGoalPublic = data["isGoalPublic"] as? Bool ?? false
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        
        // Parse workout stats with defaults
        let totalWorkouts = data["totalWorkouts"] as? Int ?? 0
        let totalWeightLifted = data["totalWeightLifted"] as? Double ?? 0.0
        let lastWorkoutDate = (data["lastWorkoutDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        
        return UserProfile(
            id: id,
            username: username,
            firstName: firstName,
            lastName: lastName,
            bio: bio,
            friendIds: friendIds,
            createdAt: createdAt,
            fitnessGoal: fitnessGoal,
            isGoalPublic: isGoalPublic,
            totalWorkouts: totalWorkouts,
            totalWeightLifted: totalWeightLifted,
            lastWorkoutDate: lastWorkoutDate
        )
    }
    
    // MARK: - Exercise Conversion
    
    static func dictionaryToRoutineExercise(_ data: [String: Any]) throws -> RoutineExercise {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let defaultSets = data["defaultSets"] as? Int else {
            throw FirebaseError.invalidData
        }
        
        var exercise = RoutineExercise(name: name, defaultSets: defaultSets)
        exercise.id = UUID(uuidString: id) ?? UUID()
        return exercise
    }
    
    static func dictionaryToSessionExercise(_ data: [String: Any]) throws -> WorkoutSessionExercise {
        guard let id = data["id"] as? String,
              let exerciseName = data["exerciseName"] as? String,
              let setsData = data["sets"] as? [[String: Any]] else {
            throw FirebaseError.invalidData
        }
        
        var sets: [WorkoutSet] = []
        for setData in setsData {
            if let set = try? dictionaryToWorkoutSet(setData) {
                sets.append(set)
            }
        }
        
        var exercise = WorkoutSessionExercise(exerciseName: exerciseName, numberOfSets: 0)
        exercise.id = UUID(uuidString: id) ?? UUID()
        exercise.sets = sets
        return exercise
    }
    
    static func dictionaryToWorkoutSet(_ data: [String: Any]) throws -> WorkoutSet {
        guard let id = data["id"] as? String,
              let weight = data["weight"] as? Double,
              let reps = data["reps"] as? Int else {
            throw FirebaseError.invalidData
        }
        
        var set = WorkoutSet(setNumber: 1)
        set.weight = weight
        set.reps = reps
        set.notes = data["notes"] as? String ?? ""
        set.id = UUID(uuidString: id) ?? UUID()
        return set
    }
    
    // MARK: - Friend Request Conversion
    
    static func dictionaryToFriendRequest(_ data: [String: Any], documentId: String) throws -> FriendRequest {
        guard let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let status = data["status"] as? String,
              let createdAtTimestamp = data["createdAt"] as? TimeInterval else {
            throw FirebaseError.invalidData
        }
        
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        let acceptedAt = (data["acceptedAt"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        let rejectedAt = (data["rejectedAt"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        
        return FriendRequest(
            id: documentId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            status: status,
            createdAt: createdAt,
            acceptedAt: acceptedAt,
            rejectedAt: rejectedAt
        )
    }
}
