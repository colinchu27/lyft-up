//
//  AuthenticationView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
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
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 20) {
                        // Enhanced Logo and Brand
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .lyftRed.opacity(0.3), radius: 12, x: 0, y: 6)
                                
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.lyftRed)
                            }
                            
                            Text("Lyft Up")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.lyftText)
                            
                            Text(isSignUp ? "Create your account" : "Welcome back")
                                .font(.title3)
                                .foregroundColor(.lyftTextSecondary)
                        }
                    }
                    
                    // Enhanced Form
                    VStack(spacing: 28) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.lyftText)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(LyftTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.lyftText)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(LyftTextFieldStyle())
                        }
                        
                        // Confirm Password Field (Sign Up Only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .foregroundColor(.lyftText)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(LyftTextFieldStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action Button
                    Button(action: handleAuthentication) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: isSignUp ? "person.badge.plus" : "person.fill")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .buttonStyle(LyftButtonStyle())
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 24)
                    
                    // Enhanced Toggle Sign In/Sign Up
                    Button(action: { 
                        isSignUp.toggle()
                        clearForm()
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.lyftRed)
                            .font(.system(size: 15, weight: .medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.lyftRed.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !confirmPassword.isEmpty && 
                   password == confirmPassword &&
                   password.count >= 6 &&
                   email.contains("@")
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }
    
    private func handleAuthentication() {
        isLoading = true
        errorMessage = ""
        
        print("Starting authentication process...")
                       print("Authentication process started")
        print("Is Sign Up: \(isSignUp)")
        
        Task {
            do {
                if isSignUp {
                    print("Attempting to sign up...")
                    try await firebaseService.signUp(email: email, password: password)
                    print("Sign up successful!")
                } else {
                    print("Attempting to sign in...")
                    try await firebaseService.signIn(email: email, password: password)
                    print("Sign in successful!")
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("Authentication error: \(error)")
                print("Error localized description: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
