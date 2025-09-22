//
//  UserSession.swift
//  Commune-iOS
//
//  Created by Cihan Canik on 3.11.2022.
//

import Foundation
import SwiftUI

final class UserSession {
    private static var instance: UserSession?
    class var shared: UserSession {
        if instance == nil {
            instance = UserSession()
        }
        return instance!
    }

    static var accessKeychainKey: String { "blainks_access_token" }
    static var refreshKeychainKey: String { "blainks_refresh_token" }

    var accessToken: String? {
        get {
            Keychain.shared.get(forKey: Self.accessKeychainKey)
        }
        set {
            Keychain.shared.save(newValue, forKey: Self.accessKeychainKey)
        }
    }

    var refreshToken: String? {
        get {
            Keychain.shared.get(forKey: Self.refreshKeychainKey)
        }
        set {
            Keychain.shared.save(newValue, forKey: Self.refreshKeychainKey)
        }
    }

    func clear() {
        Keychain.shared[UserSession.accessKeychainKey] = nil
        Keychain.shared[UserSession.refreshKeychainKey] = nil
    }

    class func clear() {
        Keychain.shared[UserSession.accessKeychainKey] = nil
        Keychain.shared[UserSession.refreshKeychainKey] = nil
    }
}
