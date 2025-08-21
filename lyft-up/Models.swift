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

struct UserProfile: Codable, Identifiable {
    let id: String
    let username: String
    let firstName: String
    let lastName: String
    let bio: String
    var friendIds: [String]
    var createdAt: Date
    var fitnessGoal: String
    var isGoalPublic: Bool
    var totalWorkouts: Int
    var totalWeightLifted: Double
    var lastWorkoutDate: Date?
    var profilePhotoURL: String?
    
    init(id: String, username: String, firstName: String = "", lastName: String = "", bio: String = "", friendIds: [String] = [], createdAt: Date = Date(), fitnessGoal: String = "", isGoalPublic: Bool = false, totalWorkouts: Int = 0, totalWeightLifted: Double = 0.0, lastWorkoutDate: Date? = nil, profilePhotoURL: String? = nil) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.friendIds = friendIds
        self.createdAt = createdAt
        self.fitnessGoal = fitnessGoal
        self.isGoalPublic = isGoalPublic
        self.totalWorkouts = totalWorkouts
        self.totalWeightLifted = totalWeightLifted
        self.lastWorkoutDate = lastWorkoutDate
        self.profilePhotoURL = profilePhotoURL
    }
}

struct Friend: Codable, Identifiable {
    let id = UUID()
    let userId: String
    let friendId: String
    let friendshipDate: Date
    
    init(userId: String, friendId: String) {
        self.userId = userId
        self.friendId = friendId
        self.friendshipDate = Date()
    }
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let status: String // "pending", "accepted", "rejected"
    let createdAt: Date
    let acceptedAt: Date?
    let rejectedAt: Date?
    
    init(id: String, fromUserId: String, toUserId: String, status: String, createdAt: Date, acceptedAt: Date? = nil, rejectedAt: Date? = nil) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
        self.rejectedAt = rejectedAt
    }
}

struct WorkoutHistory: Codable, Identifiable {
    var id = UUID()
    let userId: String
    var workouts: [Workout]
    var createdAt: Date
    
    init(userId: String) {
        self.userId = userId
        self.workouts = []
        self.createdAt = Date()
    }
}

struct Exercise: Identifiable {
    var id = UUID()
    var name: String
    var sets: Int = 3
    var reps: Int = 10
    var weight: Double = 0.0
}

// MARK: - Routine Models
struct Routine: Codable, Identifiable {
    var id = UUID()
    var name: String
    var exercises: [RoutineExercise]
    var createdAt: Date
    
    init(name: String) {
        self.name = name
        self.exercises = []
        self.createdAt = Date()
    }
}

struct RoutineExercise: Codable, Identifiable {
    var id = UUID()
    var name: String
    var defaultSets: Int
    
    init(name: String, defaultSets: Int = 3) {
        self.name = name
        self.defaultSets = defaultSets
    }
}

// MARK: - Workout Session Models
struct WorkoutSession: Codable, Identifiable {
    var id = UUID()
    var routineName: String
    var exercises: [WorkoutSessionExercise]
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool = false
    
    init(routineName: String) {
        self.routineName = routineName
        self.exercises = []
        self.startTime = Date()
    }
}

struct WorkoutSessionExercise: Codable, Identifiable {
    var id = UUID()
    var exerciseName: String
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
    var id = UUID()
    let setNumber: Int
    var weight: Double = 0.0
    var reps: Int = 0
    var isCompleted: Bool = false
    var notes: String = ""
    
    init(setNumber: Int) {
        self.setNumber = setNumber
    }
}

// MARK: - Workout Statistics Model
struct WorkoutStats: Codable {
    var totalWorkouts: Int
    var lastWorkoutDate: Date?
    var totalWeightLifted: Double
    
    init() {
        self.totalWorkouts = 0
        self.lastWorkoutDate = nil
        self.totalWeightLifted = 0.0
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let friendListUpdated = Notification.Name("friendListUpdated")
}

// MARK: - Progress Tracking Models
struct ExerciseProgress: Codable, Identifiable {
    let id = UUID()
    let exerciseName: String
    let date: Date
    let maxWeight: Double
    let maxReps: Int
    let totalVolume: Double
    let sets: Int
    
    init(exerciseName: String, date: Date, maxWeight: Double, maxReps: Int, totalVolume: Double, sets: Int) {
        self.exerciseName = exerciseName
        self.date = date
        self.maxWeight = maxWeight
        self.maxReps = maxReps
        self.totalVolume = totalVolume
        self.sets = sets
    }
}

struct ProgressMetrics: Codable {
    var weeklyWorkouts: Int
    var monthlyWorkouts: Int
    var streakDays: Int
    var averageWorkoutDuration: TimeInterval
    var totalDurationThisWeek: TimeInterval
    var totalDurationThisMonth: TimeInterval
    var totalVolumeThisWeek: Double
    var totalVolumeThisMonth: Double
    var totalWorkouts: Int
    var exerciseProgress: [ExerciseProgress]
    
    init() {
        self.weeklyWorkouts = 0
        self.monthlyWorkouts = 0
        self.streakDays = 0
        self.averageWorkoutDuration = 0
        self.totalDurationThisWeek = 0
        self.totalDurationThisMonth = 0
        self.totalVolumeThisWeek = 0
        self.totalVolumeThisMonth = 0
        self.totalWorkouts = 0
        self.exerciseProgress = []
    }
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

struct WeeklyProgress: Identifiable {
    let id = UUID()
    let weekStart: Date
    let workouts: Int
    let totalVolume: Double
    let averageDuration: TimeInterval
}
