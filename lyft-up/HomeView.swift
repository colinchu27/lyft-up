//
//  HomeView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var statsStorage = WorkoutStatsStorage.shared
    @StateObject private var analyticsService = ProgressAnalyticsService.shared
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.lyftGradientStart, Color.lyftGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
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
                    // Also trigger Firebase sync when user pulls to refresh
                    WorkoutStatsStorage.shared.recalculateStatsFromSessions()
                }
            }
            .onAppear {
                Task {
                    await firebaseService.refreshUserProfile()
                }
                // Force reload from Firebase to ensure stats are up to date
                analyticsService.reloadFromFirebase()
                
                // Also trigger stats recalculation to ensure Firebase is updated
                WorkoutStatsStorage.shared.recalculateStatsFromSessions()
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
                    
                    // Profile Photo
                    ProfilePhotoView(
                        userId: firebaseService.userProfile?.id ?? "",
                        currentPhotoURL: firebaseService.userProfile?.profilePhotoURL,
                        size: 60
                    ) { photoURL in
                        // Update the user profile with the new photo URL
                        if let userId = firebaseService.userProfile?.id {
                            Task {
                                await firebaseService.updateUserProfilePhotoURL(userId: userId, photoURL: photoURL)
                            }
                        }
                    }
                }
                
                // Motivational Quote
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.lyftRed.opacity(0.6))
                    
                    Text(dailyMotivationalQuote)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lyftTextSecondary)
                        .italic()
                    
                    Spacer()
                }
            }
            .padding(24)
            .lyftCard()
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
                .onAppear {
                    print("HomeView - ProgressAnalytics total: \(analyticsService.progressMetrics.totalWorkouts)")
                    print("HomeView - Firebase userProfile total: \(firebaseService.userProfile?.totalWorkouts ?? 0)")
                }
                
                HomeStatCard(
                    icon: "dumbbell.fill",
                    title: "Total Weight",
                    value: formatWeight(analyticsService.getTotalVolume()),
                    color: .orange
                )
                .onAppear {
                    print("HomeView - ProgressAnalytics total weight: \(analyticsService.getTotalVolume())")
                    print("HomeView - Firebase userProfile total weight: \(firebaseService.userProfile?.totalWeightLifted ?? 0)")
                }
                
                LastWorkoutCard()
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
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .shadow(color: .lyftRed.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
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
                    .padding(18)
                    .lyftCard()
                }
                .buttonStyle(PlainButtonStyle())
                
                // Friends Button
                Button(action: {
                    selectedTab = 2 // Navigate to friends tab
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
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
                    .padding(18)
                    .lyftCard()
                }
                .buttonStyle(PlainButtonStyle())
                
                // View Progress Button
                Button(action: {
                    selectedTab = 3 // Navigate to progress tab
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20))
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
                    .padding(18)
                    .lyftCard()
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
    
    private func formatWeight(_ weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if weight >= 1000 {
            let thousandsWeight = weight / 1000
            formatter.maximumFractionDigits = 1
            return "\(formatter.string(from: NSNumber(value: thousandsWeight)) ?? "0")K lbs"
        } else {
            // For smaller weights, show full number
            return "\(formatter.string(from: NSNumber(value: weight)) ?? "0") lbs"
        }
    }
    
    // MARK: - Motivational Quotes
    private let motivationalQuotes = [
        "Every workout is progress. Keep pushing!",
        "Strength doesn't come from what you can do. It comes from overcoming the things you once thought you couldn't.",
        "The only bad workout is the one that didn't happen.",
        "Your body can stand almost anything. It's your mind you have to convince.",
        "Make yourself proud. Every rep counts."
    ]
    
    private var dailyMotivationalQuote: String {
        let calendar = Calendar.current
        let today = Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        // Use the day of year to select a quote (ensures same quote all day)
        let quoteIndex = (dayOfYear - 1) % motivationalQuotes.count
        return motivationalQuotes[quoteIndex]
    }
}

// MARK: - Supporting Views
struct HomeStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.2), color.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.2), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lyftText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lyftTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .lyftCard()
    }
}

struct LastWorkoutCard: View {
    @StateObject private var statsStorage = WorkoutStatsStorage.shared
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                if let lastWorkoutDate = statsStorage.stats.lastWorkoutDate {
                    Text(formatLastWorkoutDate(lastWorkoutDate))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lyftText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Last workout")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.lyftTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("No workouts")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lyftText)
                        .lineLimit(1)
                    
                    Text("Start your journey")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.lyftTextSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatLastWorkoutDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days < 7 {
                return "\(days) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            }
        }
    }
}



#Preview {
    HomeView(selectedTab: .constant(0))
}
