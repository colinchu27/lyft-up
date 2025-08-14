//
//  AddFriendView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

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
