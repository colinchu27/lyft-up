//
//  ProfileView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var showingWorkoutHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("John Doe")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Fitness Enthusiast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                                Image(systemName: "dumbbell")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Workout Streak")
                                Spacer()
                                Text("5 days")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            HStack {
                                Image(systemName: "flame")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("Total Workouts")
                                Spacer()
                                Text("23")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                Text("Goals Achieved")
                                Spacer()
                                Text("8")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
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
                                Text("12 friends")
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
            .sheet(isPresented: $showingWorkoutHistory) {
                WorkoutHistoryView()
            }
        }
    }
}

#Preview {
    ProfileView()
}
