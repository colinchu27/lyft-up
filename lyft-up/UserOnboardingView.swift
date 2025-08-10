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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Complete Your Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Tell us a bit about yourself")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 24) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                TextField("Enter username", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
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
                            
                            if username.count > 0 {
                                usernameStatusText
                            }
                        }
                        
                        // First Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Last Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Bio Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Tell us about your fitness goals...", text: $bio, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Complete Profile Button
                    Button(action: completeProfile) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            
                            Text("Complete Profile")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
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
        !username.isEmpty && 
        !firstName.isEmpty && 
        !lastName.isEmpty &&
        username.count >= 3 &&
        usernameStatus == .available
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
    
    private func completeProfile() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Create user profile with all the information
                let userProfile = UserProfile(
                    id: firebaseService.currentUser?.uid ?? "",
                    username: username,
                    firstName: firstName,
                    lastName: lastName,
                    bio: bio
                )
                
                // Save to Firebase
                try await firebaseService.saveUserProfile(userProfile)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
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
}

// MARK: - Username Status Enum
enum UsernameStatus {
    case none
    case checking
    case available
    case taken
    case invalid
}


#Preview {
    UserOnboardingView()
}
