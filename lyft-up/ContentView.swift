//
//  ContentView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutStorage = WorkoutStorage()
    @StateObject private var sessionStorage = WorkoutSessionStorage()
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
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.lyftRed.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.lyftRed)
                }
                
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                        .scaleEffect(1.2)
                    
                    Text("Loading Lyft Up...")
                        .font(.system(size: 18, weight: .semibold))
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

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .environmentObject(firebaseService)
        .accentColor(.lyftRed) // Set tab bar accent color
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.91, green: 0.12, blue: 0.12, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.91, green: 0.12, blue: 0.12, alpha: 1.0)
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
