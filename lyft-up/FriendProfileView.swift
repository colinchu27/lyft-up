//
//  FriendProfileView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct FriendProfileView: View {
    let friend: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var recentWorkouts: [WorkoutSession] = []
    @State private var routines: [Routine] = []
    @State private var isLoadingWorkouts = true
    @State private var isLoadingRoutines = true
    
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
                        StatCard(title: "Workouts Completed", value: "\(friend.totalWorkouts)")
                        StatCard(title: "Weight Lifted", value: "\(Int(friend.totalWeightLifted))lbs")
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
                    
                    // Routines Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Routines")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.lyftText)
                        
                        if isLoadingRoutines {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                                    .scaleEffect(0.8)
                                Text("Loading routines...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.lyftText.opacity(0.6))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        } else if routines.isEmpty {
                            Text("No routines to display")
                                .font(.system(size: 16))
                                .foregroundColor(.lyftText.opacity(0.6))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(routines) { routine in
                                    FriendRoutineRow(routine: routine)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.lyftText)
                        
                        if isLoadingWorkouts {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                                    .scaleEffect(0.8)
                                Text("Loading recent workouts...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.lyftText.opacity(0.6))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        } else if recentWorkouts.isEmpty {
                            Text("No recent workouts to display")
                                .font(.system(size: 16))
                                .foregroundColor(.lyftText.opacity(0.6))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(recentWorkouts, id: \.id) { workout in
                                    RecentWorkoutRow(workout: workout)
                                }
                            }
                        }
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
        .onAppear {
            loadRecentWorkouts()
            loadRoutines()
        }
    }
    
    private func loadRecentWorkouts() {
        Task {
            do {
                let workouts = try await FirebaseService.shared.loadWorkoutSessionsForUser(friend.id)
                await MainActor.run {
                    self.recentWorkouts = workouts
                    self.isLoadingWorkouts = false
                }
            } catch {
                print("Error loading recent workouts for friend: \(error)")
                await MainActor.run {
                    self.isLoadingWorkouts = false
                }
            }
        }
    }
    
    private func loadRoutines() {
        Task {
            do {
                let loadedRoutines = try await FirebaseService.shared.loadRoutinesForUser(friend.id)
                await MainActor.run {
                    self.routines = loadedRoutines
                    self.isLoadingRoutines = false
                }
            } catch {
                print("Error loading routines for friend: \(error)")
                await MainActor.run {
                    self.isLoadingRoutines = false
                }
            }
        }
    }
}
