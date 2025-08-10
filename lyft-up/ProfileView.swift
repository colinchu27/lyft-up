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
            ZStack {
                // Background
                Color.lyftGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header Card
                        VStack(spacing: 20) {
                            // Profile Avatar
                            ZStack {
                                Circle()
                                    .fill(Color.lyftRed.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.lyftRed)
                            }
                            
                            VStack(spacing: 8) {
                                Text(userDisplayName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.lyftText)
                                
                                Text(userBio)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.lyftTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, 32)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Fitness Stats Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your Fitness Profile")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.lyftText)
                            
                            VStack(spacing: 16) {
                                // Total Workouts
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.lyftRed.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.lyftRed)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Workouts")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.lyftTextSecondary)
                                        Text("\(statsStorage.stats.totalWorkouts)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.lyftText)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Total Weight Lifted
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.lyftRed.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.lyftRed)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Weight Lifted")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.lyftTextSecondary)
                                        Text("\(Int(statsStorage.stats.totalWeightLifted)) lbs")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.lyftText)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Fitness Goal Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.lyftRed.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "target")
                                        .font(.system(size: 16))
                                        .foregroundColor(.lyftRed)
                                }
                                
                                Text("Fitness Goal")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.lyftText)
                                
                                Spacer()
                                
                                Button(action: { showingEditProfile = true }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.lyftRed)
                                }
                            }
                            
                            if let profile = firebaseService.userProfile, !profile.fitnessGoal.isEmpty {
                                Text(profile.fitnessGoal)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.lyftText)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.lyftGray)
                                    .cornerRadius(12)
                            } else {
                                Text("Set your fitness goal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.lyftTextSecondary)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.lyftGray)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Workout History Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.lyftRed.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 16))
                                        .foregroundColor(.lyftRed)
                                }
                                
                                Text("Workout History")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.lyftText)
                                
                                Spacer()
                                
                                Button(action: { showingWorkoutHistory = true }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.lyftRed)
                                }
                            }
                            
                            Text("Track your progress and review past workouts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.lyftTextSecondary)
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Friends Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.lyftRed.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.lyftRed)
                                }
                                
                                Text("Friends")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.lyftText)
                                
                                Spacer()
                                
                                Text("0 friends")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.lyftTextSecondary)
                            }
                            
                            Text("Connect with friends to share workouts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.lyftTextSecondary)
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit Profile") {
                        showingEditProfile = true
                    }
                    .foregroundColor(.lyftRed)
                    .font(.system(size: 16, weight: .medium))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.lyftRed)
                    .font(.system(size: 16, weight: .medium))
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
                } else {
                    // Load workout stats from Firebase user profile
                    statsStorage.loadFromFirebase()
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
