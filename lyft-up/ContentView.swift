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
    
    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
