//
//  FirebaseFriendService.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirebaseFriendService {
    private let db = Firestore.firestore()
    
    // MARK: - User Search
    
    // Search for users by username
    func searchUsers(byUsername username: String, currentUserId: String, loadUserProfileById: @escaping (String) async throws -> UserProfile?) async throws -> [UserProfile] {
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
    
    // MARK: - Friend Requests
    
    // Send friend request
    func sendFriendRequest(from currentUserId: String, to userId: String, loadUserProfileById: @escaping (String) async throws -> UserProfile?) async throws {
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
    func getPendingFriendRequests(for currentUserId: String) async throws -> [FriendRequest] {
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
                return try FirebaseDataConverter.dictionaryToFriendRequest(document.data(), documentId: document.documentID)
            }
            
            print("✅ Successfully parsed \(requests.count) friend requests")
            return requests
        } catch {
            print("❌ Error getting pending friend requests: \(error)")
            throw error
        }
    }
    
    // Accept friend request
    func acceptFriendRequest(_ request: FriendRequest, currentUserId: String, addFriendToUser: @escaping (String, String) async throws -> Void) async throws {
        do {
            // Update request status to accepted
            try await db.collection("friendRequests")
                .document(request.id)
                .updateData([
                    "status": "accepted",
                    "acceptedAt": Date().timeIntervalSince1970
                ])
            
            // Add each user to the other's friend list
            try await addFriendToUser(currentUserId, request.fromUserId)
            try await addFriendToUser(request.fromUserId, currentUserId)
            
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
    
    // MARK: - Friend Management
    
    // Load user's friends
    func loadFriends(for currentUserId: String, loadUserProfileById: @escaping (String) async throws -> UserProfile?) async throws -> [UserProfile] {
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
    func removeFriend(_ friendId: String, currentUserId: String, removeFriendFromUser: @escaping (String, String) async throws -> Void) async throws {
        do {
            // Remove from both users' friend lists
            try await removeFriendFromUser(currentUserId, friendId)
            try await removeFriendFromUser(friendId, currentUserId)
            
            print("Friend removed successfully")
        } catch {
            print("Error removing friend: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Functions
    
    // Helper function to add friend to user's friend list
    func addFriendToUser(userId: String, friendId: String) async throws {
        let userRef = db.collection("users").document(userId)
        
        try await userRef.updateData([
            "friendIds": FieldValue.arrayUnion([friendId])
        ])
    }
    
    // Helper function to remove friend from user's friend list
    func removeFriendFromUser(userId: String, friendId: String) async throws {
        let userRef = db.collection("users").document(userId)
        
        try await userRef.updateData([
            "friendIds": FieldValue.arrayRemove([friendId])
        ])
    }
    
    // MARK: - Debug Functions
    
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
}
