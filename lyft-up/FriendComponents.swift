//
//  FriendComponents.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct FriendRowView: View {
    let friend: UserProfile
    @State private var showingProfile = false
    
    var body: some View {
        Button(action: {
            showingProfile = true
        }) {
            HStack(spacing: 16) {
                // Profile Photo
                ProfilePhotoView(
                    userId: friend.id,
                    currentPhotoURL: friend.profilePhotoURL,
                    size: 50
                ) { _ in }
                
                // Friend Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(friendDisplayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text("@\(friend.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.lyftText.opacity(0.6))
                    
                    if !friend.fitnessGoal.isEmpty {
                        Text(friend.fitnessGoal)
                            .font(.system(size: 12))
                            .foregroundColor(.lyftText.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(friend.totalWorkouts)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lyftRed)
                    
                    Text("workouts")
                        .font(.system(size: 12))
                        .foregroundColor(.lyftText.opacity(0.6))
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProfile) {
            FriendProfileView(friend: friend)
        }
    }
    
    private var friendDisplayName: String {
        if !friend.firstName.isEmpty && !friend.lastName.isEmpty {
            return "\(friend.firstName) \(friend.lastName)"
        } else if !friend.firstName.isEmpty {
            return friend.firstName
        } else {
            return friend.username
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var requesterProfile: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo
            if let profile = requesterProfile {
                ProfilePhotoView(
                    userId: profile.id,
                    currentPhotoURL: profile.profilePhotoURL,
                    size: 50
                ) { _ in }
            } else {
                Circle()
                    .fill(Color.lyftText.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .lyftRed))
                            .scaleEffect(0.8)
                    )
            }
            
            // Requester Info
            VStack(alignment: .leading, spacing: 4) {
                if let profile = requesterProfile {
                    Text(profileDisplayName(profile))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text("@\(profile.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.lyftText.opacity(0.6))
                } else {
                    Text("Loading...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText.opacity(0.6))
                }
                
                Text("Wants to be your friend")
                    .font(.system(size: 12))
                    .foregroundColor(.lyftText.opacity(0.7))
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadRequesterProfile()
        }
    }
    
    private func loadRequesterProfile() {
        Task {
            do {
                let profile = try await FirebaseService.shared.loadUserProfileById(request.fromUserId)
                await MainActor.run {
                    self.requesterProfile = profile
                    self.isLoading = false
                }
            } catch {
                print("Error loading requester profile: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func profileDisplayName(_ profile: UserProfile) -> String {
        if !profile.firstName.isEmpty && !profile.lastName.isEmpty {
            return "\(profile.firstName) \(profile.lastName)"
        } else if !profile.firstName.isEmpty {
            return profile.firstName
        } else {
            return profile.username
        }
    }
}

struct ActivityFeedItemView: View {
    let activityItem: ActivityFeedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with friend info and date
            HStack {
                // Friend Profile Photo
                ProfilePhotoView(
                    userId: activityItem.friendId,
                    currentPhotoURL: nil, // We don't have profile photo URL in the activity item
                    size: 40
                ) { _ in }
                
                // Friend Name and Date
                VStack(alignment: .leading, spacing: 2) {
                    Text(friendDisplayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text(timeAgoString)
                        .font(.system(size: 12))
                        .foregroundColor(.lyftText.opacity(0.6))
                }
                
                Spacer()
                
                // Workout Icon
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.lyftRed)
            }
            
            // Workout Details
            VStack(alignment: .leading, spacing: 8) {
                Text("Completed \(activityItem.workoutSession.routineName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lyftText)
                
                // Exercise count
                Text("\(activityItem.workoutSession.exercises.count) exercises")
                    .font(.system(size: 12))
                    .foregroundColor(.lyftText.opacity(0.7))
                
                // Workout duration if available
                if let endTime = activityItem.workoutSession.endTime {
                    let duration = endTime.timeIntervalSince(activityItem.workoutSession.startTime)
                    let minutes = Int(duration / 60)
                    Text("Duration: \(minutes) minutes")
                        .font(.system(size: 12))
                        .foregroundColor(.lyftText.opacity(0.7))
                }
            }
            .padding(.leading, 52) // Align with text below profile photo
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var friendDisplayName: String {
        if !activityItem.friendFirstName.isEmpty && !activityItem.friendLastName.isEmpty {
            return "\(activityItem.friendFirstName) \(activityItem.friendLastName)"
        } else if !activityItem.friendFirstName.isEmpty {
            return activityItem.friendFirstName
        } else {
            return activityItem.friendUsername
        }
    }
    
    private var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: activityItem.completedAt, relativeTo: Date())
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
