//
//  EditProfileView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService.shared
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var fitnessGoal: String = ""
    @State private var isGoalPublic: Bool = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCheckingUsername = false
    @State private var usernameStatus: UsernameStatus = .none
    @State private var originalUsername = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background
                LinearGradient(
                    gradient: Gradient(colors: [Color.lyftGradientStart, Color.lyftGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Photo Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Profile Photo")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.lyftText)
                            
                            HStack {
                                Spacer()
                                ProfilePhotoView(
                                    userId: firebaseService.userProfile?.id ?? "",
                                    currentPhotoURL: firebaseService.userProfile?.profilePhotoURL,
                                    size: 100
                                ) { photoURL in
                                    // Update the user profile with the new photo URL
                                    if let userId = firebaseService.userProfile?.id {
                                        Task {
                                            await firebaseService.updateUserProfilePhotoURL(userId: userId, photoURL: photoURL)
                                            // Refresh the user profile to ensure all views update
                                            await firebaseService.refreshUserProfile()
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .lyftCard()
                        .padding(.horizontal, 20)
                        
                        // Personal Information Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Personal Information")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.lyftText)
                            
                            VStack(spacing: 16) {
                                // First Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("First Name")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.lyftText)
                                    
                                    TextField("First Name", text: $firstName)
                                        .textFieldStyle(LyftTextFieldStyle())
                                }
                                
                                // Last Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Last Name")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.lyftText)
                                    
                                    TextField("Last Name", text: $lastName)
                                        .textFieldStyle(LyftTextFieldStyle())
                                }
                                
                                // Username
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Username")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.lyftText)
                                    
                                    HStack {
                                        TextField("Username", text: $username)
                                            .textFieldStyle(LyftTextFieldStyle())
                                            .onChange(of: username) { _ in
                                                checkUsernameAvailability()
                                            }
                                        
                                        if isCheckingUsername {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.lyftRed)
                                        } else {
                                            usernameStatusIcon
                                        }
                                    }
                                    
                                    if username.count > 0 && username != originalUsername {
                                        usernameStatusText
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Bio Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Bio")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.lyftText)
                            
                            TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                                .textFieldStyle(LyftTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Fitness Goal Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Fitness Goal")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.lyftText)
                            
                            VStack(spacing: 16) {
                                TextField("What's your fitness goal?", text: $fitnessGoal, axis: .vertical)
                                    .textFieldStyle(LyftTextFieldStyle())
                                    .lineLimit(2...4)
                                
                                Toggle("Make goal public", isOn: $isGoalPublic)
                                    .toggleStyle(SwitchToggleStyle(tint: .lyftRed))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.lyftText)
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: saveProfile) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Text(isLoading ? "Saving..." : "Save Changes")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .buttonStyle(LyftButtonStyle())
                        .disabled(isLoading || !isFormValid)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.lyftRed)
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (username == originalUsername || usernameStatus == .available)
    }
    
    private func loadCurrentProfile() {
        if let profile = firebaseService.userProfile {
            firstName = profile.firstName
            lastName = profile.lastName
            username = profile.username
            originalUsername = profile.username
            bio = profile.bio
            fitnessGoal = profile.fitnessGoal
            isGoalPublic = profile.isGoalPublic
        }
    }
    
    private func saveProfile() {
        guard let currentProfile = firebaseService.userProfile else {
            errorMessage = "No profile found"
            showingError = true
            return
        }
        
        isLoading = true
        
        // Create updated profile
        let updatedProfile = UserProfile(
            id: currentProfile.id,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            friendIds: currentProfile.friendIds,
            createdAt: currentProfile.createdAt,
            fitnessGoal: fitnessGoal.trimmingCharacters(in: .whitespacesAndNewlines),
            isGoalPublic: isGoalPublic,
            totalWorkouts: currentProfile.totalWorkouts,
            totalWeightLifted: currentProfile.totalWeightLifted,
            lastWorkoutDate: currentProfile.lastWorkoutDate
        )
        
        Task {
            do {
                try await firebaseService.saveUserProfile(updatedProfile)
                await MainActor.run {
                    // Update the local profile
                    firebaseService.userProfile = updatedProfile
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private var usernameStatusIcon: some View {
        Group {
            switch usernameStatus {
            case .none:
                EmptyView()
            case .checking:
                ProgressView()
                    .scaleEffect(0.8)
                    .foregroundColor(.lyftRed)
            case .available:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .taken:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.lyftRed)
            case .invalid:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var usernameStatusText: some View {
        Group {
            switch usernameStatus {
            case .none:
                EmptyView()
            case .checking:
                Text("Checking availability...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lyftTextSecondary)
            case .available:
                Text("Username is available!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            case .taken:
                Text("Username is already taken")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lyftRed)
            case .invalid:
                Text("Username must be at least 3 characters")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func checkUsernameAvailability() {
        guard username.count >= 3 else {
            usernameStatus = .invalid
            return
        }
        
        // Don't check if username hasn't changed
        guard username != originalUsername else {
            usernameStatus = .none
            return
        }
        
        // Reset status and start checking
        usernameStatus = .checking
        isCheckingUsername = true
        
        Task {
            do {
                let isAvailable = try await firebaseService.isUsernameAvailable(username)
                await MainActor.run {
                    usernameStatus = isAvailable ? .available : .taken
                    isCheckingUsername = false
                }
            } catch {
                await MainActor.run {
                    usernameStatus = .none
                    isCheckingUsername = false
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
}
