//
//  lyft_upApp.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI
import FirebaseCore
import Firebase
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Verify GoogleService-Info.plist configuration
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            print("GoogleService-Info.plist found")
            if let projectId = plist["PROJECT_ID"] as? String {
                print("Firebase Project ID: \(projectId)")
            }
            if let bundleId = plist["BUNDLE_ID"] as? String {
                print("Bundle ID: \(bundleId)")
            }
        } else {
            print("ERROR: GoogleService-Info.plist not found or invalid!")
        }
        
        // Print Firebase configuration details
        if let app = FirebaseApp.app() {
            print("Firebase app name: \(app.name)")
            print("Firebase app options: \(app.options)")
        }
        
        // Configure Firestore settings for offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
        
        // Test Auth configuration
        let auth = Auth.auth()
        print("Firebase Auth instance created: \(auth)")
        
        print("Firebase configured successfully")
        print("Firebase Auth is ready")
        return true
    }
}

@main
struct lyft_upApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Verify Firebase is configured
                    if FirebaseApp.app() != nil {
                        print("Firebase is ready to use")
                    } else {
                        print("Firebase configuration failed")
                    }
                }
        }
    }
}
