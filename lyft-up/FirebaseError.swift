//
//  FirebaseError.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation

enum FirebaseError: Error, LocalizedError {
    case userNotAuthenticated
    case documentNotFound
    case invalidData
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case userNotFound
    case wrongPassword
    case authenticationFailed(String)
    case cannotAddSelf
    case friendRequestAlreadySent
    case alreadyFriends
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .userNotFound:
            return "No account found with this email address"
        case .wrongPassword:
            return "Incorrect password"
        case .authenticationFailed(let message):
            return message
        case .cannotAddSelf:
            return "You cannot add yourself as a friend"
        case .friendRequestAlreadySent:
            return "Friend request already sent"
        case .alreadyFriends:
            return "You are already friends with this user"
        }
    }
}
