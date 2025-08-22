//
//  FriendComponents.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct FriendRowView: View {
    let friend: UserProfile
    @State private var showingFriendProfile = false
    
    var body: some View {
        Button(action: {
            showingFriendProfile = true
        }) {
            HStack(spacing: 16) {
                // Profile Photo or Placeholder
                if let photoURL = friend.profilePhotoURL, !photoURL.isEmpty, !photoURL.hasPrefix("local_photo_") {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .shadow(color: .lyftRed.opacity(0.15), radius: 4, x: 0, y: 2)
                    } placeholder: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .shadow(color: .lyftRed.opacity(0.15), radius: 4, x: 0, y: 2)
                            .overlay(
                                Text(String(friend.firstName.prefix(1) + friend.lastName.prefix(1)))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.lyftRed)
                            )
                    }
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: .lyftRed.opacity(0.15), radius: 4, x: 0, y: 2)
                        .overlay(
                            Text(String(friend.firstName.prefix(1) + friend.lastName.prefix(1)))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.lyftRed)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(friend.firstName) \(friend.lastName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text("@\(friend.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.lyftText.opacity(0.6))
                    
                    if !friend.fitnessGoal.isEmpty && friend.isGoalPublic {
                        Text(friend.fitnessGoal)
                            .font(.system(size: 12))
                            .foregroundColor(.lyftText.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(friend.totalWorkouts)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lyftRed)
                    
                    Text("workouts")
                        .font(.system(size: 12))
                        .foregroundColor(.lyftText.opacity(0.6))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.lyftText.opacity(0.4))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .lyftCard()
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFriendProfile) {
            FriendProfileView(friend: friend)
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var fromUser: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        HStack(spacing: 16) {
            if isLoading {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                            .scaleEffect(0.8)
                    )
            } else if let user = fromUser {
                // Profile Photo or Placeholder
                if let photoURL = user.profilePhotoURL, !photoURL.isEmpty, !photoURL.hasPrefix("local_photo_") {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .shadow(color: .lyftRed.opacity(0.15), radius: 4, x: 0, y: 2)
                    } placeholder: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .shadow(color: .lyftRed.opacity(0.15), radius: 4, x: 0, y: 2)
                            .overlay(
                                Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.lyftRed)
                            )
                    }
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: .lyftRed.opacity(0.15), radius: 4, x: 0, y: 2)
                        .overlay(
                            Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.lyftRed)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let user = fromUser {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.lyftText.opacity(0.6))
                } else {
                    Text("Loading...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText.opacity(0.6))
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.lyftRed)
                        .cornerRadius(20)
                }
                
                Button(action: onReject) {
                    Text("Reject")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lyftText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadFromUser()
        }
    }
    
    private func loadFromUser() {
        Task {
            do {
                let user = try await FirebaseService.shared.loadUserProfileById(request.fromUserId)
                await MainActor.run {
                    self.fromUser = user
                    self.isLoading = false
                }
            } catch {
                print("Error loading from user: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct RecentWorkoutRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Workout icon
            Circle()
                .fill(Color.lyftRed.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.lyftRed)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.routineName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lyftText)
                
                Text(formatWorkoutDate(workout.startTime))
                    .font(.system(size: 14))
                    .foregroundColor(.lyftText.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.exercises.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lyftRed)
                
                Text("exercises")
                    .font(.system(size: 12))
                    .foregroundColor(.lyftText.opacity(0.6))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.lyftRed)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.lyftText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
