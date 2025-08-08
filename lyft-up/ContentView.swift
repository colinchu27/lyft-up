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
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Lyft Up...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var mainTabView: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            RoutineBuilderView()
                .environmentObject(workoutStorage)
                .environmentObject(sessionStorage)
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Routines")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .environmentObject(firebaseService)
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
