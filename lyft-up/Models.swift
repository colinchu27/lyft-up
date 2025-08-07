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
