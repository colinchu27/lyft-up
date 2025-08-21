//
//  ProfilePhotoManager.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI
import FirebaseFirestore

class ProfilePhotoManager: ObservableObject {
    static let shared = ProfilePhotoManager()
    private let firestore = Firestore.firestore()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // Simplified upload - for now, we'll just update the profile with a placeholder URL
    // In a full implementation, you would upload to Firebase Storage and get a real URL
    func uploadProfilePhoto(userId: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // For now, we'll create a placeholder URL and store the image locally
        // In a real implementation, you would upload to Firebase Storage
        let placeholderURL = "profile_photo_\(userId)_\(Date().timeIntervalSince1970)"
        
        // Update user profile in Firestore
        updateUserProfilePhotoURL(userId: userId, photoURL: placeholderURL) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    completion(.success(placeholderURL))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Update user profile with photo URL
    private func updateUserProfilePhotoURL(userId: String, photoURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = firestore.collection("users").document(userId)
        
        userRef.updateData([
            "profilePhotoURL": photoURL
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // Delete profile photo
    func deleteProfilePhoto(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Remove photo URL from user profile
        updateUserProfilePhotoURL(userId: userId, photoURL: "") { result in
            DispatchQueue.main.async {
                self.isLoading = false
                completion(result)
            }
        }
    }
    
    // Get profile photo URL for a user
    func getProfilePhotoURL(userId: String) -> String? {
        // This would typically fetch from Firestore, but for now we'll return nil
        // The actual URL should be stored in the UserProfile model
        return nil
    }
}
