//
//  HomeView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Logo and Welcome
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.lyftRed.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "house.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.lyftRed)
                            }
                            
                            Text("Home")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.lyftText)
                        }
                        
                        // Welcome Message
                        VStack(spacing: 16) {
                            Text("Welcome to Lyft Up!")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.lyftText)
                            
                            // User welcome message
                            if firebaseService.userProfile != nil {
                                VStack(spacing: 8) {
                                    Text("Welcome back,")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.lyftTextSecondary)
                                    
                                    Text(userDisplayName)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.lyftRed)
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // Quick Actions Card
                        VStack(spacing: 20) {
                            Text("Quick Actions")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.lyftText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 16) {
                                // Start Workout Button
                                Button(action: {
                                    // Navigate to workout session
                                }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.lyftRed.opacity(0.1))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.lyftRed)
                                        }
                                        
                                        Text("Start Workout")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.lyftText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.lyftGray)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // View Routines Button
                                Button(action: {
                                    // Navigate to routines tab (index 1)
                                    selectedTab = 1
                                }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.lyftRed.opacity(0.1))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "list.bullet.clipboard")
                                                .font(.system(size: 20))
                                                .foregroundColor(.lyftRed)
                                        }
                                        
                                        Text("View Routines")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.lyftText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.lyftGray)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
            }
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
    HomeView(selectedTab: .constant(0))
}
