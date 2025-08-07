//
//  ContentView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutStorage = WorkoutStorage()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            LogWorkoutView()
                .environmentObject(workoutStorage)
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Log Workout")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    ContentView()
}
