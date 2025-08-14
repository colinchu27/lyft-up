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

// Custom Color Extension for the app's color scheme
extension Color {
    static let lyftRed = Color(red: 0.91, green: 0.12, blue: 0.12)
    static let lyftRedLight = Color(red: 0.95, green: 0.15, blue: 0.15)
    static let lyftRedDark = Color(red: 0.75, green: 0.10, blue: 0.10)
    static let lyftGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let lyftGrayDark = Color(red: 0.90, green: 0.90, blue: 0.90)
    static let lyftText = Color(red: 0.20, green: 0.20, blue: 0.20)
    static let lyftTextSecondary = Color(red: 0.60, green: 0.60, blue: 0.60)
}

// Custom Button Style
struct LyftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.lyftRed)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Custom Text Field Style
struct LyftTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.lyftGray)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.lyftRed.opacity(0.3), lineWidth: 1)
            )
    }
}

// Username Status Enum
enum UsernameStatus {
    case none
    case checking
    case available
    case taken
    case invalid
}

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
                    
                    // Initialize progress analytics service
                    _ = ProgressAnalyticsService.shared
                }
                .preferredColorScheme(.light) // Force light mode for consistent white background
        }
    }
}
