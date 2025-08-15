//
//  HomeView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var analyticsService = ProgressAnalyticsService.shared
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.lyftGray, Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Quick Stats Section
                        quickStatsSection
                        
                        // Quick Actions Section
                        quickActionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .refreshable {
                    analyticsService.reloadFromFirebase()
                }
            }
            .onAppear {
                Task {
                    await firebaseService.refreshUserProfile()
                }
                // Force reload from Firebase to ensure stats are up to date
                analyticsService.reloadFromFirebase()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Welcome Card
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back!")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.lyftTextSecondary)
                        
                        Text(userDisplayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.lyftText)
                    }
                    
                    Spacer()
                    
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(Color.lyftRed.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.lyftRed)
                    }
                }
                
                // Motivational Quote
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.lyftRed.opacity(0.6))
                    
                    Text("Every workout is progress. Keep pushing!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lyftTextSecondary)
                        .italic()
                    
                    Spacer()
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
            )
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.lyftText)
                
                Spacer()
                
                Button(action: {
                    selectedTab = 3 // Navigate to progress tab
                }) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lyftRed)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                HomeStatCard(
                    icon: "flame.fill",
                    title: "Workouts",
                    value: "\(analyticsService.progressMetrics.totalWorkouts)",
                    color: .lyftRed
                )
                
                HomeStatCard(
                    icon: "dumbbell.fill",
                    title: "Total Weight",
                    value: "\(Int(analyticsService.getTotalVolume()))lbs",
                    color: .orange
                )
                
                HomeStatCard(
                    icon: "calendar",
                    title: "Last Workout",
                    value: analyticsService.getLastWorkoutDate() != nil ? "Recent" : "None",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.lyftText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Start Workout Button
                Button(action: {
                    selectedTab = 1 // Navigate to routines tab
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.lyftRed.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.lyftRed)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Workout")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.lyftText)
                            
                            Text("Begin your fitness journey")
                                .font(.system(size: 14))
                                .foregroundColor(.lyftTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lyftTextSecondary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Friends Button
                Button(action: {
                    selectedTab = 2 // Navigate to friends tab
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connect with Friends")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.lyftText)
                            
                            Text("Stay motivated together")
                                .font(.system(size: 14))
                                .foregroundColor(.lyftTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lyftTextSecondary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
                // View Progress Button
                Button(action: {
                    selectedTab = 3 // Navigate to progress tab
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("View Progress")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.lyftText)
                            
                            Text("Track your fitness journey")
                                .font(.system(size: 14))
                                .foregroundColor(.lyftTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lyftTextSecondary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
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

// MARK: - Supporting Views
struct HomeStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lyftText)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lyftTextSecondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}



#Preview {
    HomeView(selectedTab: .constant(0))
}
