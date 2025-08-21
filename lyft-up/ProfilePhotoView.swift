//
//  ProfilePhotoView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI
import PhotosUI

struct ProfilePhotoView: View {
    let userId: String
    let currentPhotoURL: String?
    let size: CGFloat
    let onPhotoUpdated: ((String) -> Void)?
    
    @StateObject private var photoManager = ProfilePhotoManager.shared
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    @State private var profileImage: UIImage?
    
    init(userId: String, currentPhotoURL: String? = nil, size: CGFloat = 120, onPhotoUpdated: ((String) -> Void)? = nil) {
        self.userId = userId
        self.currentPhotoURL = currentPhotoURL
        self.size = size
        self.onPhotoUpdated = onPhotoUpdated
    }
    
    var body: some View {
        ZStack {
            // Profile Photo or Placeholder
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.lyftRed.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .lyftRed.opacity(0.2), radius: 8, x: 0, y: 4)
            } else if let photoURL = currentPhotoURL, !photoURL.isEmpty, !photoURL.hasPrefix("profile_photo_") {
                // Only show AsyncImage for real URLs, not our placeholder URLs
                AsyncImage(url: URL(string: photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.lyftRed.opacity(0.2), lineWidth: 2)
                        )
                        .shadow(color: .lyftRed.opacity(0.2), radius: 8, x: 0, y: 4)
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
            
            // Loading overlay
            if photoManager.isLoading {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: size, height: size)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
            
            // Edit button overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingActionSheet = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.lyftRed)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.trailing, 4)
                .padding(.bottom, 4)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: selectedItem) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = image
                        uploadPhoto(image: image)
                    }
                }
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
        .confirmationDialog("Profile Photo", isPresented: $showingActionSheet) {
            Button("Take Photo") {
                // Camera functionality would go here
                showingImagePicker = true
            }
            Button("Choose from Library") {
                showingImagePicker = true
            }
            if currentPhotoURL != nil && !currentPhotoURL!.isEmpty {
                Button("Remove Photo", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Remove Profile Photo", isPresented: $showingDeleteAlert) {
            Button("Remove", role: .destructive) {
                deletePhoto()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove your profile photo?")
        }
        .alert("Error", isPresented: .constant(photoManager.errorMessage != nil)) {
            Button("OK") {
                photoManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = photoManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.lyftRed.opacity(0.2), Color.lyftRed.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .lyftRed.opacity(0.2), radius: 8, x: 0, y: 4)
            
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.lyftRed)
        }
    }
    
    private func uploadPhoto(image: UIImage) {
        photoManager.uploadProfilePhoto(userId: userId, image: image) { result in
            switch result {
            case .success(let photoURL):
                onPhotoUpdated?(photoURL)
            case .failure(let error):
                print("Failed to upload photo: \(error.localizedDescription)")
            }
        }
    }
    
    private func deletePhoto() {
        photoManager.deleteProfilePhoto(userId: userId) { result in
            switch result {
            case .success:
                profileImage = nil
                onPhotoUpdated?("")
            case .failure(let error):
                print("Failed to delete photo: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ProfilePhotoView(userId: "preview_user", currentPhotoURL: nil, size: 120) { photoURL in
        print("Photo updated: \(photoURL)")
    }
}
