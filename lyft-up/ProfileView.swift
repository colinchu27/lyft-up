//
//  ProfileView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var statsStorage = WorkoutStatsStorage.shared
    @State private var showingWorkoutHistory = false
    @State private var showingSignOutAlert = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(userDisplayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(userEmail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(userBio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Your Fitness Profile Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Fitness Profile")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "flame")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("Total Workouts")
                                Spacer()
                                Text("\(statsStorage.stats.totalWorkouts)")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            // Fitness Goal Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    Text("Fitness Goal")
                                    Spacer()
                                    Button(action: { showingEditProfile = true }) {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                if let profile = firebaseService.userProfile, !profile.fitnessGoal.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(profile.fitnessGoal)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .padding(.horizontal, 20)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Set your fitness goal")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            

                        }
                        .padding(.vertical, 16)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Workout History Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Workout History")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Button(action: { showingWorkoutHistory = true }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    Text("View Workout History")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("Track your progress and review past workouts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }
                        .padding(.vertical, 16)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Friends Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Friends")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Workout Buddies")
                                Spacer()
                                Text("0 friends")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            Text("Connect with friends to share workouts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }
                        .padding(.vertical, 16)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
                               .navigationTitle("Profile")
                   .navigationBarTitleDisplayMode(.large)
                   .toolbar {
                       ToolbarItem(placement: .navigationBarLeading) {
                           Button("Edit Profile") {
                               showingEditProfile = true
                           }
                           .foregroundColor(.blue)
                       }
                       
                       ToolbarItem(placement: .navigationBarTrailing) {
                           Button("Sign Out") {
                               showingSignOutAlert = true
                           }
                           .foregroundColor(.red)
                       }
                   }
            .sheet(isPresented: $showingWorkoutHistory) {
                WorkoutHistoryView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                // Only refresh if we don't have profile data yet
                if firebaseService.userProfile == nil {
                    Task {
                        await firebaseService.refreshUserProfile()
                    }
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
    
    private var userEmail: String {
        return firebaseService.currentUser?.email ?? "No email"
    }
    
    private var userBio: String {
        if let profile = firebaseService.userProfile, !profile.bio.isEmpty {
            return profile.bio
        }
        return "Fitness enthusiast"
    }
    
    private func signOut() {
        do {
            try firebaseService.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

#Preview {
    ProfileView()
}
