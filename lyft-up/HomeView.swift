//
//  HomeView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "house.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 60))
                
                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome to Lyft Up!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // User welcome message
                if firebaseService.userProfile != nil {
                    VStack(spacing: 8) {
                        Text("Welcome back,")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(userDisplayName)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Refresh user profile when view appears
                Task {
                    await firebaseService.refreshUserProfile()
                }
            }
        }
    }
    
    private var userDisplayName: String {
        if let profile = firebaseService.userProfile {
            if !profile.firstName.isEmpty && !profile.lastName.isEmpty {
                return "\(profile.firstName) \(profile.lastName)"
            } else if !profile.firstName.isEmpty {
                return profile.firstName
            } else {
                return profile.username
            }
        }
        return "User"
    }
}

#Preview {
    HomeView()
}
