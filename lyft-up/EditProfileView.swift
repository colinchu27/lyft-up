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
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Username", text: $username)
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
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadCurrentProfile() {
        if let profile = firebaseService.userProfile {
            firstName = profile.firstName
            lastName = profile.lastName
            username = profile.username
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
}

#Preview {
    EditProfileView()
}
