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

struct FriendRowView: View {
    let friend: UserProfile
    @State private var showingFriendProfile = false
    
    var body: some View {
        Button(action: {
            showingFriendProfile = true
        }) {
            HStack(spacing: 16) {
                // Profile Image Placeholder
                Circle()
                    .fill(Color.lyftRed.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(friend.firstName.prefix(1) + friend.lastName.prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.lyftRed)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(friend.firstName) \(friend.lastName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text("@\(friend.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.lyftText.opacity(0.6))
                    
                    if !friend.fitnessGoal.isEmpty && friend.isGoalPublic {
                        Text(friend.fitnessGoal)
                            .font(.system(size: 12))
                            .foregroundColor(.lyftText.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(friend.totalWorkouts)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lyftRed)
                    
                    Text("workouts")
                        .font(.system(size: 12))
                        .foregroundColor(.lyftText.opacity(0.6))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.lyftText.opacity(0.4))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFriendProfile) {
            FriendProfileView(friend: friend)
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var fromUser: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        HStack(spacing: 16) {
            if isLoading {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                            .scaleEffect(0.8)
                    )
            } else if let user = fromUser {
                Circle()
                    .fill(Color.lyftRed.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.lyftRed)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let user = fromUser {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.lyftText.opacity(0.6))
                } else {
                    Text("Loading...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText.opacity(0.6))
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.lyftRed)
                        .cornerRadius(20)
                }
                
                Button(action: onReject) {
                    Text("Reject")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lyftText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadFromUser()
        }
    }
    
    private func loadFromUser() {
        Task {
            do {
                let user = try await FirebaseService.shared.loadUserProfileById(request.fromUserId)
                await MainActor.run {
                    self.fromUser = user
                    self.isLoading = false
                }
            } catch {
                print("Error loading from user: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var searchText = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    @State private var searchError: String?
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                        .padding()
                } else if let error = searchError {
                    errorView(error)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    noResultsView
                } else if searchText.isEmpty {
                    searchPromptView
                } else {
                    searchResultsList
                }
                
                Spacer()
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.lyftRed)
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.lyftText.opacity(0.6))
            
            TextField("Search by username...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { _ in
                    performSearch()
                }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var searchPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.lyftRed.opacity(0.3))
            
            VStack(spacing: 12) {
                Text("Find Friends")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.lyftText)
                
                Text("Search for friends by their username to add them to your network")
                    .font(.system(size: 16))
                    .foregroundColor(.lyftText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundColor(.lyftText.opacity(0.4))
            
            Text("No users found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.lyftText)
            
            Text("Try searching with a different username")
                .font(.system(size: 14))
                .foregroundColor(.lyftText.opacity(0.6))
        }
        .padding()
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Search Error")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.lyftText)
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.lyftText.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                searchError = nil
                performSearch()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.lyftRed)
            .cornerRadius(25)
        }
        .padding()
    }
    
    private var searchResultsList: some View {
        List {
            ForEach(searchResults) { user in
                SearchResultRow(user: user)
                    .environmentObject(firebaseService)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                let results = try await firebaseService.searchUsers(byUsername: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                print("Error searching users: \(error)")
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                    self.searchError = error.localizedDescription
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let user: UserProfile
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var isFriendRequestSent = false
    @State private var requestError: String?
    @State private var showingSuccessAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.lyftRed.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftRed)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lyftText)
                
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.lyftText.opacity(0.6))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Button(action: {
                    sendFriendRequest()
                }) {
                    Text(isFriendRequestSent ? "Sent" : "Add")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isFriendRequestSent ? .lyftText.opacity(0.6) : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFriendRequestSent ? Color.gray.opacity(0.2) : Color.lyftRed)
                        .cornerRadius(20)
                }
                .disabled(isFriendRequestSent)
                
                if let error = requestError {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Friend Request Sent", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your friend request has been sent to \(user.firstName)!")
        }
    }
    
    private func sendFriendRequest() {
        Task {
            do {
                try await firebaseService.sendFriendRequest(to: user.id)
                await MainActor.run {
                    isFriendRequestSent = true
                    requestError = nil
                    showingSuccessAlert = true
                }
            } catch {
                print("Error sending friend request: \(error)")
                await MainActor.run {
                    requestError = error.localizedDescription
                }
            }
        }
    }
}

struct FriendProfileView: View {
    let friend: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.lyftRed.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(friend.firstName.prefix(1) + friend.lastName.prefix(1)))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.lyftRed)
                            )
                        
                        VStack(spacing: 8) {
                            Text("\(friend.firstName) \(friend.lastName)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.lyftText)
                            
                            Text("@\(friend.username)")
                                .font(.system(size: 16))
                                .foregroundColor(.lyftText.opacity(0.6))
                        }
                        
                        if !friend.bio.isEmpty {
                            Text(friend.bio)
                                .font(.system(size: 16))
                                .foregroundColor(.lyftText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Stats Section
                    HStack(spacing: 40) {
                        StatCard(title: "Workouts", value: "\(friend.totalWorkouts)")
                        StatCard(title: "Weight Lifted", value: "\(Int(friend.totalWeightLifted))kg")
                    }
                    
                    // Fitness Goal
                    if !friend.fitnessGoal.isEmpty && friend.isGoalPublic {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fitness Goal")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.lyftText)
                            
                            Text(friend.fitnessGoal)
                                .font(.system(size: 16))
                                .foregroundColor(.lyftText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent Activity Placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.lyftText)
                        
                        Text("No recent workouts to display")
                            .font(.system(size: 16))
                            .foregroundColor(.lyftText.opacity(0.6))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.lyftRed)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.lyftRed)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.lyftText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    FriendsView()
        .environmentObject(FirebaseService.shared)
}
