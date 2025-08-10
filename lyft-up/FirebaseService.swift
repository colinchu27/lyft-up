//
//  FirebaseService.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var needsOnboarding = false
    
    private init() {
        setupAuthStateListener()
    }
    
    // MARK: - Authentication
    
    private func setupAuthStateListener() {
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                if user != nil {
                    // Load user profile when authenticated
                    Task {
                        await self?.loadUserProfileOnAuth()
                    }
                } else {
                    self?.userProfile = nil
                    self?.needsOnboarding = false
                }
            }
        }
    }
    
    private func loadUserProfileOnAuth() async {
        print("loadUserProfileOnAuth called")
        do {
            if let profile = try await loadUserProfile() {
                await MainActor.run {
                    self.userProfile = profile
                    // Only set needsOnboarding if profile is incomplete
                    self.needsOnboarding = !self.isProfileComplete(profile)
                    print("User profile loaded on auth: \(profile.username)")
                    if self.needsOnboarding {
                        print("Profile is incomplete, needs onboarding")
                    }
                }
            } else {
                await MainActor.run {
                    self.needsOnboarding = true
                    print("No user profile found, needs onboarding")
                }
            }
        } catch {
            print("Error loading user profile on auth: \(error)")
            await MainActor.run {
                self.needsOnboarding = true
            }
        }
    }
    
    func signInAnonymously() async throws {
        do {
            _ = try await auth.signInAnonymously()
            print("Signed in anonymously successfully")
        } catch {
            print("Error signing in anonymously: \(error)")
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            print("Attempting to create user with email")
            _ = try await auth.createUser(withEmail: email, password: password)
            print("User signed up successfully")
            
            // Don't create a profile here - let the onboarding flow handle it
            // This ensures new users go through the onboarding process
            await MainActor.run {
                self.needsOnboarding = true
            }
            print("User needs onboarding")
        } catch {
            print("Error signing up: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Provide more specific error messages
            if let authError = error as? AuthErrorCode {
                switch authError.code {
                case .emailAlreadyInUse:
                    throw FirebaseError.emailAlreadyInUse
                case .weakPassword:
                    throw FirebaseError.weakPassword
                case .invalidEmail:
                    throw FirebaseError.invalidEmail
                default:
                    throw FirebaseError.authenticationFailed(error.localizedDescription)
                }
            } else {
                throw FirebaseError.authenticationFailed(error.localizedDescription)
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            print("Attempting to sign in with email")
            _ = try await auth.signIn(withEmail: email, password: password)
            print("User signed in successfully")
        } catch {
            print("Error signing in: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Provide more specific error messages
            if let authError = error as? AuthErrorCode {
                switch authError.code {
                case .userNotFound:
                    throw FirebaseError.userNotFound
                case .wrongPassword:
                    throw FirebaseError.wrongPassword
                case .invalidEmail:
                    throw FirebaseError.invalidEmail
                default:
                    throw FirebaseError.authenticationFailed(error.localizedDescription)
                }
            } else {
                throw FirebaseError.authenticationFailed(error.localizedDescription)
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            print("Password reset email sent successfully")
        } catch {
            print("Error sending password reset: \(error)")
            throw error
        }
    }
    
    // MARK: - Workout Sessions
    
    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            let sessionData = try sessionToDictionary(session)
            try await db.collection("users").document(userId)
                .collection("workoutSessions")
                .document(session.id.uuidString)
                .setData(sessionData)
            
            print("Workout session saved successfully")
        } catch {
            print("Error saving workout session: \(error)")
            throw error
        }
    }
    
    func loadWorkoutSessions() async throws -> [WorkoutSession] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("workoutSessions")
                .order(by: "startTime", descending: true)
                .getDocuments()
            
            let sessions = try snapshot.documents.compactMap { document in
                try dictionaryToSession(document.data())
            }
            
            print("Loaded \(sessions.count) workout sessions")
            return sessions
        } catch {
            print("Error loading workout sessions: \(error)")
            throw error
        }
    }
    
    // MARK: - Routines
    
    func saveRoutine(_ routine: Routine) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            let routineData = try routineToDictionary(routine)
            try await db.collection("users").document(userId)
                .collection("routines")
                .document(routine.id.uuidString)
                .setData(routineData)
            
            print("Routine saved successfully")
        } catch {
            print("Error saving routine: \(error)")
            throw error
        }
    }
    
    func loadRoutines() async throws -> [Routine] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("routines")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let routines = try snapshot.documents.compactMap { document in
                try dictionaryToRoutine(document.data())
            }
            
            print("Loaded \(routines.count) routines")
            return routines
        } catch {
            print("Error loading routines: \(error)")
            throw error
        }
    }
    
    func deleteRoutine(_ routine: Routine) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
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
    
    // MARK: - User Profile
    
    func saveUserProfile(_ userProfile: UserProfile) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            let userData = try userProfileToDictionary(userProfile)
            try await db.collection("users").document(userId)
                .setData(userData)
            
            print("User profile saved successfully")
        } catch {
            print("Error saving user profile: \(error)")
            throw error
        }
    }
    
    func loadUserProfile() async throws -> UserProfile? {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            print("Loading user profile")
            let document = try await db.collection("users").document(userId).getDocument()
            guard let data = document.data() else { 
                print("No user profile found")
                return nil 
            }
            
            let profile = try dictionaryToUserProfile(data)
            print("Successfully loaded user profile: \(profile.username)")
            return profile
        } catch {
            print("Error loading user profile: \(error)")
            throw error
        }
    }
    
    // Check if user profile is complete
    private func isProfileComplete(_ profile: UserProfile) -> Bool {
        // For now, just check if username exists - make it more lenient
        let isComplete = !profile.username.isEmpty
        print("Profile completeness check - Username: '\(profile.username)', IsComplete: \(isComplete)")
        return isComplete
    }
    
    // Public function to manually trigger onboarding (for profile editing)
    func startOnboarding() {
        needsOnboarding = true
        print("Manually triggered onboarding")
    }
    
    // Public function to force complete onboarding (for debugging)
    func forceCompleteOnboarding() {
        needsOnboarding = false
        print("Force completed onboarding")
    }
    
    // Public function to check and fix onboarding state
    func checkAndFixOnboardingState() {
        print("Checking onboarding state...")
        print("Current needsOnboarding: \(needsOnboarding)")
        print("Current userProfile: \(userProfile?.username ?? "nil")")
        
        if let profile = userProfile {
            let isComplete = isProfileComplete(profile)
            print("Profile is complete: \(isComplete)")
            if isComplete && needsOnboarding {
                print("Fixing: Profile is complete but needsOnboarding is true")
                needsOnboarding = false
            }
        } else {
            print("No user profile found")
        }
    }
    
    // Public function to refresh user profile
    func refreshUserProfile() async {
        do {
            if let profile = try await loadUserProfile() {
                await MainActor.run {
                    self.userProfile = profile
                    // Only set needsOnboarding if profile is incomplete
                    self.needsOnboarding = !self.isProfileComplete(profile)
                    print("User profile refreshed: \(profile.username)")
                    if self.needsOnboarding {
                        print("Profile is incomplete, needs onboarding")
                    }
                }
            } else {
                // Only set needsOnboarding if we don't already have a profile loaded
                await MainActor.run {
                    if self.userProfile == nil {
                        self.needsOnboarding = true
                        print("No user profile found, needs onboarding")
                    } else {
                        print("Profile refresh failed but we have existing profile data")
                    }
                }
            }
        } catch {
            print("Error refreshing user profile: \(error)")
            // Don't set needsOnboarding on error if we already have profile data
            await MainActor.run {
                if self.userProfile == nil {
                    self.needsOnboarding = true
                } else {
                    print("Profile refresh error but keeping existing profile data")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func sessionToDictionary(_ session: WorkoutSession) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(session)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        return dictionary
    }
    
    private func dictionaryToSession(_ data: [String: Any]) throws -> WorkoutSession {
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
    
    private func routineToDictionary(_ routine: Routine) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(routine)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        return dictionary
    }
    
    private func dictionaryToRoutine(_ data: [String: Any]) throws -> Routine {
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
    
    private func userProfileToDictionary(_ userProfile: UserProfile) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(userProfile)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        return dictionary
    }
    
    private func dictionaryToUserProfile(_ data: [String: Any]) throws -> UserProfile {
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
    
    private func dictionaryToRoutineExercise(_ data: [String: Any]) throws -> RoutineExercise {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let defaultSets = data["defaultSets"] as? Int else {
            throw FirebaseError.invalidData
        }
        
        var exercise = RoutineExercise(name: name, defaultSets: defaultSets)
        exercise.id = UUID(uuidString: id) ?? UUID()
        return exercise
    }
    
    private func dictionaryToSessionExercise(_ data: [String: Any]) throws -> WorkoutSessionExercise {
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
    
    private func dictionaryToWorkoutSet(_ data: [String: Any]) throws -> WorkoutSet {
        guard let id = data["id"] as? String,
              let weight = data["weight"] as? Double,
              let reps = data["reps"] as? Int else {
            throw FirebaseError.invalidData
        }
        
        var set = WorkoutSet(setNumber: 1)
        set.weight = weight
        set.reps = reps
        set.id = UUID(uuidString: id) ?? UUID()
        return set
    }
}

// MARK: - Custom Errors

enum FirebaseError: Error, LocalizedError {
    case userNotAuthenticated
    case documentNotFound
    case invalidData
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case userNotFound
    case wrongPassword
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .userNotFound:
            return "No account found with this email address"
        case .wrongPassword:
            return "Incorrect password"
        case .authenticationFailed(let message):
            return message
        }
    }
}
