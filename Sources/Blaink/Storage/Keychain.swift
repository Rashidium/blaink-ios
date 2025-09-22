//
//  Keychain.swift
//
//
//  Created by Rashid Ramazanov on 11/25/22.
//

import Foundation

class Keychain: DataSavable {
    static let shared = Keychain()
    var savable: DataSavable

    var blainkDeviceId: String {
        createOrReturn(withKey: "blainkDeviceId")
    }

    var blainkClientId: String {
        createOrReturn(withKey: "blainkClientId")
    }

    func createOrReturn(withKey key: String) -> String {
        if let id = Keychain.shared[key] {
            return id
        }
        let id = UUID().uuidString
        Keychain.shared[key] = id
        return id
    }

    var pushNotificationToken: String? {
        get {
            savable["pushNotificationToken"]
        }
        set {
            savable["pushNotificationToken"] = newValue
        }
    }

    private init() {
        // prevents annoying keychain permission while development
        #if DEBUG && os(macOS)
        savable = UserDefaultsSavable()
        #else
        savable = KeychainSavable()
        #endif
    }

    subscript(key: String) -> String? {
        get {
            savable[key]
        }
        set {
            savable[key] = newValue
        }
    }

    func save(_ value: (some Encodable)?, forKey key: String) {
        savable.save(value, forKey: key)
    }

    func get<V>(forKey key: String) -> V? where V: Decodable {
        savable.get(forKey: key)
    }
}
