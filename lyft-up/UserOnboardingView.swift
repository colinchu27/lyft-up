//
//  UserOnboardingView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct UserOnboardingView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var bio = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isCheckingUsername = false
    @State private var usernameStatus: UsernameStatus = .none
    @State private var profilePhotoURL: String = ""
    
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
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 20) {
                            // Profile Photo Selection
                            ProfilePhotoView(
                                userId: firebaseService.currentUser?.uid ?? "",
                                currentPhotoURL: nil,
                                size: 120
                            ) { photoURL in
                                // Store the photo URL for later use when creating the profile
                                profilePhotoURL = photoURL
                                print("Profile photo URL set during onboarding: \(photoURL)")
                            }
                            
                            VStack(spacing: 12) {
                                Text("Complete Your Profile")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.lyftText)
                                
                                Text("Tell us a bit about yourself")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.lyftTextSecondary)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 24) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Username")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.lyftText)
                                
                                HStack {
                                    TextField("Enter username", text: $username)
                                        .textFieldStyle(LyftTextFieldStyle())
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
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
                                
                                if username.count > 0 {
                                    usernameStatusText
                                }
                            }
                            
                            // First Name Field
                            VStack(alignment: .leading, spacing: 12) {
                                Text("First Name")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.lyftText)
                                
                                TextField("Enter first name", text: $firstName)
                                    .textFieldStyle(LyftTextFieldStyle())
                            }
                            
                            // Last Name Field
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Last Name")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.lyftText)
                                
                                TextField("Enter last name", text: $lastName)
                                    .textFieldStyle(LyftTextFieldStyle())
                            }
                            
                            // Bio Field
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Bio")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.lyftText)
                                
                                TextField("Tell us about your fitness goals...", text: $bio, axis: .vertical)
                                    .textFieldStyle(LyftTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Complete Profile Button
                        Button(action: completeProfile) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Text(isLoading ? "Creating Profile..." : "Complete Profile")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .buttonStyle(LyftButtonStyle())
                        .disabled(!isFormValid || isLoading)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        usernameStatus == .available
    }
    
    private func completeProfile() {
        guard let user = firebaseService.currentUser else {
            errorMessage = "No user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let profile = UserProfile(
            id: user.uid,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            friendIds: [],
            createdAt: Date(),
            fitnessGoal: "",
            isGoalPublic: false,
            profilePhotoURL: profilePhotoURL.isEmpty ? nil : profilePhotoURL
        )
        
        Task {
            do {
                try await firebaseService.saveUserProfile(profile)
                await MainActor.run {
                    firebaseService.userProfile = profile
                    firebaseService.needsOnboarding = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
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
    UserOnboardingView()
}
