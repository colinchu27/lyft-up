//
//  ContentView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutStorage = WorkoutStorage()
    @StateObject private var sessionStorage = WorkoutSessionStorage.shared
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var isLoading = true
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if firebaseService.isAuthenticated {
                if firebaseService.needsOnboarding && firebaseService.userProfile == nil {
                    UserOnboardingView()
                } else {
                    mainTabView
                }
            } else {
                authenticationView
            }
        }
        .onAppear {
            setupAuthentication()
            print("ContentView - isAuthenticated: \(firebaseService.isAuthenticated)")
            print("ContentView - needsOnboarding: \(firebaseService.needsOnboarding)")
            print("ContentView - userProfile: \(firebaseService.userProfile?.username ?? "nil")")
        }
    }
    
    private var loadingView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.lyftGradientStart, Color.lyftGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: .lyftRed.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.lyftRed)
                }
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                        .scaleEffect(1.4)
                    
                    Text("Loading Lyft Up...")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.lyftText)
                }
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            RoutineBuilderView()
                .environmentObject(workoutStorage)
                .environmentObject(sessionStorage)
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Routines")
                }
                .tag(1)

            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag(2)

            ProgressDashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .environmentObject(firebaseService)
        .accentColor(.lyftRed) // Set tab bar accent color
        .onAppear {
            // Enhanced tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // Add subtle shadow to tab bar
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            appearance.shadowImage = UIImage()
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.91, green: 0.12, blue: 0.12, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.91, green: 0.12, blue: 0.12, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private var authenticationView: some View {
        AuthenticationView()
    }
    
    private func setupAuthentication() {
        // The FirebaseService.authStateListener will automatically handle authentication state
        // We just need to stop showing the loading screen after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
