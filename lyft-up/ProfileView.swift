//
//  ProfileView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ProfileView: View {
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
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Recent Workouts")
                                Spacer()
                                Text("View All")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 20)
                            
                            Text("Your workout history will appear here")
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
        }
    }
}

#Preview {
    ProfileView()
}
