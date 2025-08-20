//
//  FirebaseAuthService.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import Firebase
import FirebaseAuth

class FirebaseAuthService: ObservableObject {
    private let auth = Auth.auth()
    
    func signInAnonymously() async throws {
        do {
            _ = try await auth.signInAnonymously()
            print("Signed in anonymously successfully")
        } catch {
            print("Error signing in anonymously: \(error)")
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            print("Attempting to create user with email")
            _ = try await auth.createUser(withEmail: email, password: password)
            print("User signed up successfully")
        } catch {
            print("Error signing up: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Provide more specific error messages
            if let authError = error as? AuthErrorCode {
                switch authError.code {
                case .emailAlreadyInUse:
                    throw FirebaseError.emailAlreadyInUse
                case .weakPassword:
                    throw FirebaseError.weakPassword
                case .invalidEmail:
                    throw FirebaseError.invalidEmail
                default:
                    throw FirebaseError.authenticationFailed(error.localizedDescription)
                }
            } else {
                throw FirebaseError.authenticationFailed(error.localizedDescription)
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            print("Attempting to sign in with email")
            _ = try await auth.signIn(withEmail: email, password: password)
            print("User signed in successfully")
        } catch {
            print("Error signing in: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Provide more specific error messages
            if let authError = error as? AuthErrorCode {
                switch authError.code {
                case .userNotFound:
                    throw FirebaseError.userNotFound
                case .wrongPassword:
                    throw FirebaseError.wrongPassword
                case .invalidEmail:
                    throw FirebaseError.invalidEmail
                default:
                    throw FirebaseError.authenticationFailed(error.localizedDescription)
                }
            } else {
                throw FirebaseError.authenticationFailed(error.localizedDescription)
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            print("Password reset email sent successfully")
        } catch {
            print("Error sending password reset: \(error)")
            throw error
        }
    }
    
    func getCurrentUser() -> FirebaseAuth.User? {
        return auth.currentUser
    }
    
    func addAuthStateListener(_ listener: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return auth.addStateDidChangeListener { _, user in
            listener(user)
        }
    }
}
