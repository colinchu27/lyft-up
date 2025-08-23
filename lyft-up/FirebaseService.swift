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
    private let authService = FirebaseAuthService()
    private let userService = FirebaseUserService()
    private let workoutService = FirebaseWorkoutService()
    private let friendService = FirebaseFriendService()
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var needsOnboarding = false
    
    private init() {
        setupAuthStateListener()
    }
    
    // MARK: - Authentication
    
    private func setupAuthStateListener() {
        _ = authService.addAuthStateListener { [weak self] user in
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
                    self.needsOnboarding = !self.userService.isProfileComplete(profile)
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
    
    // MARK: - Public Authentication Methods
    
    func signInAnonymously() async throws {
        try await authService.signInAnonymously()
    }
    
    func signUp(email: String, password: String) async throws {
        try await authService.signUp(email: email, password: password)
        
        // Don't create a profile here - let the onboarding flow handle it
        // This ensures new users go through the onboarding process
        await MainActor.run {
            self.needsOnboarding = true
        }
        print("User needs onboarding")
    }
    
    func signIn(email: String, password: String) async throws {
        try await authService.signIn(email: email, password: password)
    }
    
    func signOut() throws {
        try authService.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await authService.resetPassword(email: email)
    }
    
    // MARK: - Public Username Management Methods
    
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        try await userService.isUsernameAvailable(username)
    }
    
    func getUserByUsername(_ username: String) async throws -> UserProfile? {
        try await userService.getUserByUsername(username)
    }
    
    func loadUserProfileById(_ userId: String) async throws -> UserProfile? {
        try await userService.loadUserProfileById(userId)
    }
    
    // MARK: - Public Workout Session Methods
    
    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        try await workoutService.saveWorkoutSession(session, userId: userId)
    }
    
    func loadWorkoutSessions() async throws -> [WorkoutSession] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        return try await workoutService.loadWorkoutSessionsForUser(userId)
    }
    
    func loadWorkoutSessionsForUser(_ userId: String) async throws -> [WorkoutSession] {
        try await workoutService.loadWorkoutSessionsForUser(userId)
    }
    
    func deleteWorkoutSession(_ session: WorkoutSession) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        try await workoutService.deleteWorkoutSession(session, userId: userId)
    }
    
    // MARK: - Public Routine Methods
    
    func saveRoutine(_ routine: Routine) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        try await workoutService.saveRoutine(routine, userId: userId)
    }
    
    func loadRoutines() async throws -> [Routine] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        return try await workoutService.loadRoutinesForUser(userId)
    }
    
    func loadRoutinesForUser(_ userId: String) async throws -> [Routine] {
        try await workoutService.loadRoutinesForUser(userId)
    }
    
    func deleteRoutine(_ routine: Routine) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        try await workoutService.deleteRoutine(routine, userId: userId)
    }
    
    // MARK: - Public User Profile Methods
    
    func saveUserProfile(_ userProfile: UserProfile) async throws {
        try await userService.saveUserProfile(userProfile)
    }
    
    func loadUserProfile() async throws -> UserProfile? {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        return try await userService.loadUserProfile(userId: userId)
    }
    
    // MARK: - Public Profile Management Methods
    
    func startOnboarding() {
        needsOnboarding = true
        print("Manually triggered onboarding")
    }
    
    func forceCompleteOnboarding() {
        needsOnboarding = false
        print("Force completed onboarding")
    }
    
    func checkAndFixOnboardingState() {
        print("Checking onboarding state...")
        print("Current needsOnboarding: \(needsOnboarding)")
        print("Current userProfile: \(userProfile?.username ?? "nil")")
        
        if let profile = userProfile {
            let isComplete = userService.isProfileComplete(profile)
            print("Profile is complete: \(isComplete)")
            if isComplete && needsOnboarding {
                print("Fixing: Profile is complete but needsOnboarding is true")
                needsOnboarding = false
            }
        } else {
            print("No user profile found")
        }
    }
    
    func refreshUserProfile() async {
        do {
            if let profile = try await loadUserProfile() {
                await MainActor.run {
                    self.userProfile = profile
                    // Only set needsOnboarding if profile is incomplete
                    self.needsOnboarding = !self.userService.isProfileComplete(profile)
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
    
    // MARK: - Public Friend System Methods
    
    func searchUsers(byUsername username: String) async throws -> [UserProfile] {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        return try await friendService.searchUsers(byUsername: username, currentUserId: currentUserId, loadUserProfileById: userService.loadUserProfileById)
    }
    
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        try await friendService.sendFriendRequest(from: currentUserId, to: userId, loadUserProfileById: userService.loadUserProfileById)
    }
    
    func getPendingFriendRequests() async throws -> [FriendRequest] {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        return try await friendService.getPendingFriendRequests(for: currentUserId)
    }
    
    func acceptFriendRequest(_ request: FriendRequest) async throws {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        try await friendService.acceptFriendRequest(request, currentUserId: currentUserId, addFriendToUser: friendService.addFriendToUser)
    }
    
    func rejectFriendRequest(_ request: FriendRequest) async throws {
        try await friendService.rejectFriendRequest(request)
    }
    
    func loadFriends() async throws -> [UserProfile] {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        return try await friendService.loadFriends(for: currentUserId, loadUserProfileById: userService.loadUserProfileById)
    }
    
    func removeFriend(_ friendId: String) async throws {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        try await friendService.removeFriend(friendId, currentUserId: currentUserId, removeFriendFromUser: friendService.removeFriendFromUser)
    }
    
    // MARK: - Activity Feed Methods
    
    func loadFriendsRecentActivity(daysBack: Int = 5) async throws -> [ActivityFeedItem] {
        guard let currentUserId = currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        
        // Get user's friends
        let friends = try await loadFriends()
        
        // Calculate the date 5 days ago
        let calendar = Calendar.current
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        
        var activityItems: [ActivityFeedItem] = []
        
        // For each friend, get their recent workout sessions
        for friend in friends {
            do {
                let friendSessions = try await workoutService.loadWorkoutSessionsForUser(friend.id)
                
                // Filter sessions completed in the last 5 days
                let recentSessions = friendSessions.filter { session in
                    guard let endTime = session.endTime, session.isCompleted else { return false }
                    return endTime >= fiveDaysAgo
                }
                
                // Convert to ActivityFeedItem
                for session in recentSessions {
                    let activityItem = ActivityFeedItem(
                        friendId: friend.id,
                        friendUsername: friend.username,
                        friendFirstName: friend.firstName,
                        friendLastName: friend.lastName,
                        workoutSession: session,
                        completedAt: session.endTime ?? session.startTime
                    )
                    activityItems.append(activityItem)
                }
            } catch {
                print("Error loading sessions for friend \(friend.username): \(error)")
                // Continue with other friends even if one fails
                continue
            }
        }
        
        // Sort by completion date (most recent first)
        return activityItems.sorted { $0.completedAt > $1.completedAt }
    }
    
    // MARK: - Public Debug Methods
    
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
    
    func recalculateAndUpdateUserStats() async throws {
        guard let userId = currentUser?.uid,
              let profile = userProfile else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let updatedProfile = try await userService.recalculateAndUpdateUserStats(
            userId: userId,
            userProfile: profile,
            loadWorkoutSessions: workoutService.loadWorkoutSessionsForUser
        )
        
        await MainActor.run {
            self.userProfile = updatedProfile
        }
    }
    
    func updateUserProfilePhotoURL(userId: String, photoURL: String) async {
        do {
            let userRef = db.collection("users").document(userId)
            try await userRef.updateData([
                "profilePhotoURL": photoURL
            ])
            
            // Update local user profile immediately
            await MainActor.run {
                if var updatedProfile = self.userProfile {
                    updatedProfile.profilePhotoURL = photoURL
                    self.userProfile = updatedProfile
                }
            }
            
            print("✅ Profile photo URL updated successfully")
        } catch {
            print("❌ Error updating profile photo URL: \(error)")
        }
    }
    

    
    func debugAllFriendRequests() async {
        await friendService.debugAllFriendRequests()
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
