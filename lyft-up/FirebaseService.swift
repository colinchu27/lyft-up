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
                        // Debug user data to help identify issues
                        await self?.debugUserData()
                        // Clean up any global collections
                        await self?.cleanupGlobalCollections()
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
            
            return try dictionaryToUserProfile(data)
        } catch {
            print("Error loading user profile by ID: \(error)")
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
    
    func loadWorkoutSessions() async throws -> [WorkoutSession] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        return try await loadWorkoutSessionsForUser(userId)
    }
    
    func loadWorkoutSessionsForUser(_ userId: String) async throws -> [WorkoutSession] {
        do {
            let path = "users/\(userId)/workoutSessions"
            let snapshot = try await db.collection("users").document(userId)
                .collection("workoutSessions")
                .order(by: "startTime", descending: true)
                .limit(to: 10) // Limit to recent 10 workouts
                .getDocuments()
            
            let sessions = try snapshot.documents.compactMap { document in
                try dictionaryToSession(document.data())
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
    
    func deleteWorkoutSession(_ session: WorkoutSession) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
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
    
    func saveRoutine(_ routine: Routine) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            let routineData = try routineToDictionary(routine)
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
    
    func loadRoutines() async throws -> [Routine] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            let path = "users/\(userId)/routines"
            let snapshot = try await db.collection("users").document(userId)
                .collection("routines")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let routines = try snapshot.documents.compactMap { document in
                try dictionaryToRoutine(document.data())
            }
            
            print("📋 Loaded \(routines.count) routines from: \(path)")
            for routine in routines {
                print("   - \(routine.name)")
            }
            return routines
        } catch {
            print("❌ Error loading routines: \(error)")
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
            
            // Also create a username index for easy lookup
            try await db.collection("usernames").document(userProfile.username)
                .setData([
                    "userId": userId,
                    "createdAt": userProfile.createdAt.timeIntervalSince1970
                ])
            
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
    
    // MARK: - Friends System
    
    // Search for users by username
    func searchUsers(byUsername username: String) async throws -> [UserProfile] {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            // Search for usernames that contain the search term
            let snapshot = try await db.collection("usernames")
                .whereField("userId", isNotEqualTo: currentUserId) // Exclude current user
                .getDocuments()
            
            var users: [UserProfile] = []
            
            for document in snapshot.documents {
                let data = document.data()
                if let userId = data["userId"] as? String {
                    // Check if username contains search term (case insensitive)
                    let documentUsername = document.documentID
                    if documentUsername.localizedCaseInsensitiveContains(username) {
                        if let userProfile = try await loadUserProfileById(userId) {
                            users.append(userProfile)
                        }
                    }
                }
            }
            
            // Limit results to 20 users
            return Array(users.prefix(20))
        } catch {
            print("Error searching users: \(error)")
            throw error
        }
    }
    
    // Send friend request
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        print("📤 Sending friend request from \(currentUserId) to \(userId)")
        
        guard currentUserId != userId else {
            print("❌ Cannot send friend request to self")
            throw FirebaseError.cannotAddSelf
        }
        
        do {
            // Check if friend request already exists
            let existingRequest = try await db.collection("friendRequests")
                .whereField("fromUserId", isEqualTo: currentUserId)
                .whereField("toUserId", isEqualTo: userId)
                .getDocuments()
            
            print("🔍 Checking for existing requests: found \(existingRequest.documents.count)")
            
            if !existingRequest.documents.isEmpty {
                print("❌ Friend request already sent")
                throw FirebaseError.friendRequestAlreadySent
            }
            
            // Check if they are already friends
            let currentUserProfile = try await loadUserProfileById(currentUserId)
            if currentUserProfile?.friendIds.contains(userId) == true {
                print("❌ Already friends")
                throw FirebaseError.alreadyFriends
            }
            
            // Create friend request
            let requestData: [String: Any] = [
                "fromUserId": currentUserId,
                "toUserId": userId,
                "status": "pending",
                "createdAt": Date().timeIntervalSince1970
            ]
            
            print("📝 Creating friend request with data: \(requestData)")
            let docRef = try await db.collection("friendRequests").addDocument(data: requestData)
            print("✅ Friend request sent successfully with ID: \(docRef.documentID)")
        } catch {
            print("❌ Error sending friend request: \(error)")
            throw error
        }
    }
    
    // Get pending friend requests for current user
    func getPendingFriendRequests() async throws -> [FriendRequest] {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        print("🔍 Looking for pending friend requests for user: \(currentUserId)")
        
        do {
            let snapshot = try await db.collection("friendRequests")
                .whereField("toUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: "pending")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            print("📋 Found \(snapshot.documents.count) friend request documents")
            
            let requests = try snapshot.documents.compactMap { document in
                print("📄 Processing document: \(document.documentID)")
                print("📄 Document data: \(document.data())")
                return try dictionaryToFriendRequest(document.data(), documentId: document.documentID)
            }
            
            print("✅ Successfully parsed \(requests.count) friend requests")
            return requests
        } catch {
            print("❌ Error getting pending friend requests: \(error)")
            throw error
        }
    }
    
    // Accept friend request
    func acceptFriendRequest(_ request: FriendRequest) async throws {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            // Update request status to accepted
            try await db.collection("friendRequests")
                .document(request.id)
                .updateData([
                    "status": "accepted",
                    "acceptedAt": Date().timeIntervalSince1970
                ])
            
            // Add each user to the other's friend list
            try await addFriendToUser(userId: currentUserId, friendId: request.fromUserId)
            try await addFriendToUser(userId: request.fromUserId, friendId: currentUserId)
            
            print("Friend request accepted successfully")
        } catch {
            print("Error accepting friend request: \(error)")
            throw error
        }
    }
    
    // Reject friend request
    func rejectFriendRequest(_ request: FriendRequest) async throws {
        do {
            try await db.collection("friendRequests")
                .document(request.id)
                .updateData([
                    "status": "rejected",
                    "rejectedAt": Date().timeIntervalSince1970
                ])
            
            print("Friend request rejected successfully")
        } catch {
            print("Error rejecting friend request: \(error)")
            throw error
        }
    }
    
    // Load user's friends
    func loadFriends() async throws -> [UserProfile] {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            // Get current user's profile to get friend IDs
            guard let currentUserProfile = try await loadUserProfileById(currentUserId) else {
                throw FirebaseError.documentNotFound
            }
            
            var friends: [UserProfile] = []
            
            // Load each friend's profile
            for friendId in currentUserProfile.friendIds {
                if let friendProfile = try await loadUserProfileById(friendId) {
                    friends.append(friendProfile)
                }
            }
            
            return friends
        } catch {
            print("Error loading friends: \(error)")
            throw error
        }
    }
    
    // Remove friend
    func removeFriend(_ friendId: String) async throws {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        do {
            // Remove from both users' friend lists
            try await removeFriendFromUser(userId: currentUserId, friendId: friendId)
            try await removeFriendFromUser(userId: friendId, friendId: currentUserId)
            
            print("Friend removed successfully")
        } catch {
            print("Error removing friend: \(error)")
            throw error
        }
    }
    
    // Helper function to add friend to user's friend list
    private func addFriendToUser(userId: String, friendId: String) async throws {
        let userRef = db.collection("users").document(userId)
        
        try await userRef.updateData([
            "friendIds": FieldValue.arrayUnion([friendId])
        ])
    }
    
    // Helper function to remove friend from user's friend list
    private func removeFriendFromUser(userId: String, friendId: String) async throws {
        let userRef = db.collection("users").document(userId)
        
        try await userRef.updateData([
            "friendIds": FieldValue.arrayRemove([friendId])
        ])
    }
    
    // Helper function to convert dictionary to FriendRequest
    private func dictionaryToFriendRequest(_ data: [String: Any], documentId: String) throws -> FriendRequest {
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
    
    // MARK: - Debug Functions
    
    func testFirebaseConnection() async -> Bool {
        do {
            // Try to read a document to test connection
            let _ = try await db.collection("test").document("test").getDocument()
            return true
        } catch {
            print("Firebase connection test failed: \(error)")
            return false
        }
    }
    
    // Debug function to check all friend requests
    func debugAllFriendRequests() async {
        do {
            print("🔍 DEBUG: Checking all friend requests in database...")
            let snapshot = try await db.collection("friendRequests").getDocuments()
            print("📋 Total friend requests in database: \(snapshot.documents.count)")
            
            for document in snapshot.documents {
                print("📄 Document ID: \(document.documentID)")
                print("📄 Data: \(document.data())")
            }
        } catch {
            print("❌ Error checking all friend requests: \(error)")
        }
    }
    
    // MARK: - Debugging and Cleanup
    
    func debugUserData() async {
        guard let userId = currentUser?.uid else {
            print("❌ No authenticated user")
            return
        }
        
        print("🔍 Debugging data for user: \(userId)")
        
        do {
            // Check user-specific routines
            let routinesSnapshot = try await db.collection("users").document(userId)
                .collection("routines")
                .getDocuments()
            
            print("📋 User routines count: \(routinesSnapshot.documents.count)")
            for doc in routinesSnapshot.documents {
                print("   - Routine: \(doc.data()["name"] ?? "Unknown") (ID: \(doc.documentID))")
            }
            
            // Check user-specific workout sessions
            let sessionsSnapshot = try await db.collection("users").document(userId)
                .collection("workoutSessions")
                .getDocuments()
            
            print("💪 User workout sessions count: \(sessionsSnapshot.documents.count)")
            for doc in sessionsSnapshot.documents {
                print("   - Session: \(doc.data()["routineName"] ?? "Unknown") (ID: \(doc.documentID))")
            }
            
            // Check if there are any global collections (should be empty)
            let globalRoutinesSnapshot = try await db.collection("routines").getDocuments()
            let globalSessionsSnapshot = try await db.collection("workoutSessions").getDocuments()
            
            if !globalRoutinesSnapshot.documents.isEmpty {
                print("⚠️  WARNING: Found \(globalRoutinesSnapshot.documents.count) routines in global collection!")
            }
            
            if !globalSessionsSnapshot.documents.isEmpty {
                print("⚠️  WARNING: Found \(globalSessionsSnapshot.documents.count) workout sessions in global collection!")
            }
            
        } catch {
            print("❌ Error debugging user data: \(error)")
        }
    }
    
    func cleanupGlobalCollections() async {
        print("🧹 Cleaning up global collections...")
        
        do {
            // Remove any routines from global collection
            let globalRoutinesSnapshot = try await db.collection("routines").getDocuments()
            for doc in globalRoutinesSnapshot.documents {
                try await doc.reference.delete()
                print("🗑️  Deleted global routine: \(doc.documentID)")
            }
            
            // Remove any workout sessions from global collection
            let globalSessionsSnapshot = try await db.collection("workoutSessions").getDocuments()
            for doc in globalSessionsSnapshot.documents {
                try await doc.reference.delete()
                print("🗑️  Deleted global workout session: \(doc.documentID)")
            }
            
            print("✅ Global collections cleanup completed")
        } catch {
            print("❌ Error cleaning up global collections: \(error)")
        }
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
    case cannotAddSelf
    case friendRequestAlreadySent
    case alreadyFriends
    
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
        case .cannotAddSelf:
            return "You cannot add yourself as a friend"
        case .friendRequestAlreadySent:
            return "Friend request already sent"
        case .alreadyFriends:
            return "You are already friends with this user"
        }
    }
}
