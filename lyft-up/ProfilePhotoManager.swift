//
//  ProfilePhotoManager.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI
import FirebaseFirestore

// Notification for profile photo updates
extension Notification.Name {
    static let profilePhotoUpdated = Notification.Name("profilePhotoUpdated")
}

class ProfilePhotoManager: ObservableObject {
    static let shared = ProfilePhotoManager()
    private let firestore = Firestore.firestore()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Local storage for profile images
    private var profileImages: [String: UIImage] = [:]
    
    private init() {
        loadStoredImages()
    }
    
    // MARK: - Persistent Storage
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func getImagePath(for userId: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent("profile_photo_\(userId).jpg")
    }
    
    private func saveImageToDisk(_ image: UIImage, for userId: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            try data.write(to: getImagePath(for: userId))
            print("✅ Profile photo saved to disk for user: \(userId)")
        } catch {
            print("❌ Failed to save profile photo to disk: \(error)")
        }
    }
    
    private func loadImageFromDisk(for userId: String) -> UIImage? {
        let imagePath = getImagePath(for: userId)
        
        guard let data = try? Data(contentsOf: imagePath),
              let image = UIImage(data: data) else {
            return nil
        }
        
        print("✅ Profile photo loaded from disk for user: \(userId)")
        return image
    }
    
    private func deleteImageFromDisk(for userId: String) {
        let imagePath = getImagePath(for: userId)
        
        do {
            try FileManager.default.removeItem(at: imagePath)
            print("✅ Profile photo deleted from disk for user: \(userId)")
        } catch {
            print("❌ Failed to delete profile photo from disk: \(error)")
        }
    }
    
    private func loadStoredImages() {
        // Load all stored images from disk into memory
        // This would typically scan the documents directory for profile photos
        // For now, we'll load them on-demand when needed
        print("📱 ProfilePhotoManager initialized - ready to load stored images")
    }
    
    // MARK: - Public Methods
    
    // Store image locally and update profile
    func uploadProfilePhoto(userId: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Store the image in memory
        profileImages[userId] = image
        
        // Save the image to disk for persistence
        saveImageToDisk(image, for: userId)
        
        // Create a unique identifier for this photo
        let photoId = "local_photo_\(userId)_\(Date().timeIntervalSince1970)"
        
        // Update user profile in Firestore
        updateUserProfilePhotoURL(userId: userId, photoURL: photoId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    // Broadcast the update to all views
                    NotificationCenter.default.post(
                        name: .profilePhotoUpdated,
                        object: nil,
                        userInfo: ["userId": userId, "photoURL": photoId]
                    )
                    completion(.success(photoId))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Get stored image for a user
    func getProfileImage(for userId: String) -> UIImage? {
        // First check memory cache
        if let cachedImage = profileImages[userId] {
            return cachedImage
        }
        
        // If not in memory, try to load from disk
        if let diskImage = loadImageFromDisk(for: userId) {
            // Store in memory for future access
            profileImages[userId] = diskImage
            return diskImage
        }
        
        return nil
    }
    
    // Check if we have a local image for a user
    func hasLocalImage(for userId: String) -> Bool {
        return profileImages[userId] != nil || loadImageFromDisk(for: userId) != nil
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
        
        // Remove from memory
        profileImages.removeValue(forKey: userId)
        
        // Remove from disk
        deleteImageFromDisk(for: userId)
        
        // Remove photo URL from user profile
        updateUserProfilePhotoURL(userId: userId, photoURL: "") { result in
            DispatchQueue.main.async {
                self.isLoading = false
                if case .success = result {
                    // Broadcast the deletion to all views
                    NotificationCenter.default.post(
                        name: .profilePhotoUpdated,
                        object: nil,
                        userInfo: ["userId": userId, "photoURL": ""]
                    )
                }
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
