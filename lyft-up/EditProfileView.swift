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
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    
                    HStack {
                        TextField("Username", text: $username)
                            .onChange(of: username) { _ in
                                checkUsernameAvailability()
                            }
                        
                        if isCheckingUsername {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            usernameStatusIcon
                        }
                    }
                    
                    if username.count > 0 && username != originalUsername {
                        usernameStatusText
                    }
                }
                
                Section("Bio") {
                    TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Fitness Goal") {
                    TextField("What's your fitness goal?", text: $fitnessGoal, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Toggle("Make goal public", isOn: $isGoalPublic)
                }
                
                Section {
                    Button(action: saveProfile) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Saving...")
                            }
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
            isGoalPublic: isGoalPublic
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
            case .available:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .taken:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
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
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .available:
                Text("Username is available!")
                    .font(.caption)
                    .foregroundColor(.green)
            case .taken:
                Text("Username is already taken")
                    .font(.caption)
                    .foregroundColor(.red)
            case .invalid:
                Text("Username must be at least 3 characters")
                    .font(.caption)
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
