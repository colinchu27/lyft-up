//
//  FriendsView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var searchText = ""
    @State private var showingAddFriend = false
    @State private var friends: [UserProfile] = []
    @State private var pendingRequests: [FriendRequest] = []
    @State private var isLoading = false
    @State private var isLoadingRequests = false
    @State private var isFirebaseConnected = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    loadingView
                } else if friends.isEmpty && pendingRequests.isEmpty {
                    emptyStateView
                } else {
                    friendsListView
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isFirebaseConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(isFirebaseConnected ? "Connected" : "Offline")
                                .font(.system(size: 12))
                                .foregroundColor(.lyftText.opacity(0.6))
                        }
                        
                        Button("Debug") {
                            debugAllRequests()
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.lyftRed)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.lyftRed)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends...")
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .onAppear {
                testFirebaseConnection()
                loadFriends()
                loadPendingRequests()
            }
            .refreshable {
                loadFriends()
                loadPendingRequests()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                .scaleEffect(1.2)
            
            Text("Loading friends...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.lyftText)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.lyftRed.opacity(0.3))
            
            VStack(spacing: 12) {
                Text("No Friends Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.lyftText)
                
                Text("Add friends to see their workouts and stay motivated together!")
                    .font(.system(size: 16))
                    .foregroundColor(.lyftText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                showingAddFriend = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friends")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.lyftRed)
                .cornerRadius(25)
            }
        }
        .padding()
    }
    
    private var friendsListView: some View {
        List {
            if !pendingRequests.isEmpty {
                Section("Friend Requests") {
                    ForEach(pendingRequests) { request in
                        FriendRequestRow(request: request, onAccept: {
                            acceptFriendRequest(request)
                        }, onReject: {
                            rejectFriendRequest(request)
                        })
                    }
                }
            }
            
            Section("Friends") {
                ForEach(filteredFriends) { friend in
                    FriendRowView(friend: friend)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredFriends: [UserProfile] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { friend in
                friend.username.localizedCaseInsensitiveContains(searchText) ||
                friend.firstName.localizedCaseInsensitiveContains(searchText) ||
                friend.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadFriends() {
        guard let currentUser = firebaseService.userProfile else { return }
        
        isLoading = true
        
        Task {
            do {
                let loadedFriends = try await firebaseService.loadFriends()
                await MainActor.run {
                    self.friends = loadedFriends
                    self.isLoading = false
                }
            } catch {
                print("Error loading friends: \(error)")
                await MainActor.run {
                    self.friends = []
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadPendingRequests() {
        print("🔄 Loading pending friend requests...")
        isLoadingRequests = true
        
        Task {
            do {
                let requests = try await firebaseService.getPendingFriendRequests()
                print("📨 Found \(requests.count) pending friend requests")
                for request in requests {
                    print("   - Request from: \(request.fromUserId) to: \(request.toUserId)")
                }
                await MainActor.run {
                    self.pendingRequests = requests
                    self.isLoadingRequests = false
                }
            } catch {
                print("❌ Error loading pending requests: \(error)")
                await MainActor.run {
                    self.pendingRequests = []
                    self.isLoadingRequests = false
                }
            }
        }
    }
    
    private func acceptFriendRequest(_ request: FriendRequest) {
        Task {
            do {
                try await firebaseService.acceptFriendRequest(request)
                await MainActor.run {
                    // Remove from pending requests and reload friends
                    self.pendingRequests.removeAll { $0.id == request.id }
                    self.loadFriends()
                    
                    // Notify that friend list has been updated
                    NotificationCenter.default.post(name: .friendListUpdated, object: nil)
                }
            } catch {
                print("Error accepting friend request: \(error)")
            }
        }
    }
    
    private func rejectFriendRequest(_ request: FriendRequest) {
        Task {
            do {
                try await firebaseService.rejectFriendRequest(request)
                await MainActor.run {
                    // Remove from pending requests
                    self.pendingRequests.removeAll { $0.id == request.id }
                }
            } catch {
                print("Error rejecting friend request: \(error)")
            }
        }
    }
    
    private func testFirebaseConnection() {
        Task {
            let isConnected = await firebaseService.testFirebaseConnection()
            await MainActor.run {
                self.isFirebaseConnected = isConnected
            }
        }
    }
    
    private func debugAllRequests() {
        Task {
            await firebaseService.debugAllFriendRequests()
        }
    }
}

#Preview {
    FriendsView()
        .environmentObject(FirebaseService.shared)
}
