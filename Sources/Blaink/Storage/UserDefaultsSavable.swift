//
//  UserDefaultsSavable.swift
//  DataStorage
//
//  Created by Rashid Ramazanov on 1/11/23.
//

import Foundation

struct UserDefaultsSavable: DataSavable {
    subscript(key: String) -> String? {
        get {
            UserDefaults.standard.string(forKey: key)
        } set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    func save(_ value: (some Encodable)?, forKey key: String) {
        DispatchQueue.global().sync(flags: .barrier) {
            if let json = value,
               let data = try? JSONEncoder().encode(json) {
                UserDefaults.standard.set(String(data: data, encoding: .utf8), forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    func get<V: Decodable>(forKey key: String) -> V? {
        let content: String? = UserDefaults.standard.string(forKey: key)
        guard let value = content,
              let data = value.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(V.self, from: data)
    }
}
