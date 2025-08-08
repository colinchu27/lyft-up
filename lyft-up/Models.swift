//
//  Models.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation

// MARK: - Data Models
struct Workout: Codable, Identifiable {
    let id = UUID()
    let exerciseName: String
    let sets: Int
    let reps: Int
    let weight: Double
    let date: Date
}

struct User: Codable, Identifiable {
    let id = UUID()
    let username: String
    var friendIds: [UUID]
    let createdAt: Date
    
    init(username: String) {
        self.username = username
        self.friendIds = []
        self.createdAt = Date()
    }
}

struct Friend: Codable, Identifiable {
    let id = UUID()
    let userId: UUID
    let friendId: UUID
    let friendshipDate: Date
    
    init(userId: UUID, friendId: UUID) {
        self.userId = userId
        self.friendId = friendId
        self.friendshipDate = Date()
    }
}

struct WorkoutHistory: Codable, Identifiable {
    let id = UUID()
    let userId: UUID
    var workouts: [Workout]
    let createdAt: Date
    
    init(userId: UUID) {
        self.userId = userId
        self.workouts = []
        self.createdAt = Date()
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: Int = 3
    var reps: Int = 10
    var weight: Double = 0.0
}

// MARK: - Routine Models
struct Routine: Codable, Identifiable {
    let id = UUID()
    var name: String
    var exercises: [RoutineExercise]
    let createdAt: Date
    
    init(name: String) {
        self.name = name
        self.exercises = []
        self.createdAt = Date()
    }
}

struct RoutineExercise: Codable, Identifiable {
    let id = UUID()
    var name: String
    var defaultSets: Int
    
    init(name: String, defaultSets: Int = 3) {
        self.name = name
        self.defaultSets = defaultSets
    }
}

// MARK: - Workout Session Models
struct WorkoutSession: Codable, Identifiable {
    let id = UUID()
    let routineName: String
    var exercises: [WorkoutSessionExercise]
    let startTime: Date
    var endTime: Date?
    var isCompleted: Bool = false
    
    init(routineName: String) {
        self.routineName = routineName
        self.exercises = []
        self.startTime = Date()
    }
}

struct WorkoutSessionExercise: Codable, Identifiable {
    let id = UUID()
    let exerciseName: String
    var sets: [WorkoutSet]
    
    init(exerciseName: String, numberOfSets: Int) {
        self.exerciseName = exerciseName
        if numberOfSets > 0 {
            self.sets = (1...numberOfSets).map { setNumber in
                WorkoutSet(setNumber: setNumber)
            }
        } else {
            self.sets = []
        }
    }
}

struct WorkoutSet: Codable, Identifiable {
    let id = UUID()
    let setNumber: Int
    var weight: Double = 0.0
    var reps: Int = 0
    var isCompleted: Bool = false
    
    init(setNumber: Int) {
        self.setNumber = setNumber
    }
}
