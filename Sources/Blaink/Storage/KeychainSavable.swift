//
//  KeychainSavable.swift
//  Storage
//
//  Created by Rashid Ramazanov on 1/11/23.
//

import Foundation

struct KeychainSavable: DataSavable {
    let service: String
    let accessGroup: String
    init() {
        service = Bundle.main.infoDictionary?["KEYCHAIN_SERVICE"] as? String ?? ""
        let appGroup = Bundle.main.infoDictionary?["APP_GROUP_NAME"] as? String ?? ""
        let appIdentifier = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String ?? ""
        accessGroup = appIdentifier.appending(appGroup)
    }

    subscript(key: String) -> String? {
        get {
            load(with: key)
        } set {
            DispatchQueue.global().sync(flags: .barrier) {
                save(newValue, forKey: key)
            }
        }
    }

    func save(_ value: (some Encodable)?, forKey key: String) {
        DispatchQueue.global().sync(flags: .barrier) {
            if let json = value,
               let data = try? JSONEncoder().encode(json) {
                save(data, forKey: key)
            } else {
                SecItemDelete(keyChainQuery(with: key))
            }
        }
    }

    func get<V: Decodable>(forKey key: String) -> V? {
        guard let value = load(with: key),
              let data = value.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(V.self, from: data)
    }

    private func save(_ data: Data, forKey key: String) {
        let query = keyChainQuery(with: key)

        if SecItemCopyMatching(query, nil) == noErr {
            SecItemUpdate(query, NSDictionary(dictionary: [kSecValueData: data]))
        } else {
            query.setValue(data, forKey: kSecValueData as String)
            SecItemAdd(query, nil)
        }
    }

    private func save(_ string: String?, forKey key: String) {
        let query = keyChainQuery(with: key)
        let objectData: Data? = string?.data(using: .utf8, allowLossyConversion: false)

        if SecItemCopyMatching(query, nil) == noErr {
            if let dictData = objectData {
                SecItemUpdate(query, NSDictionary(dictionary: [kSecValueData: dictData]))
            } else {
                SecItemDelete(query)
            }
        } else {
            if let dictData = objectData {
                query.setValue(dictData, forKey: kSecValueData as String)
                SecItemAdd(query, nil)
            } else {
                SecItemDelete(query)
            }
        }
    }

    private func load(with key: String) -> String? {
        let query = keyChainQuery(with: key)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnAttributes as String)

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)

        guard
            let resultsDict = result as? NSDictionary,
            let resultsData = resultsDict.value(forKey: kSecValueData as String) as? Data,
            status == noErr
        else {
            return nil
        }
        return String(data: resultsData, encoding: .utf8)
    }

    private func keyChainQuery(with key: String) -> NSMutableDictionary {
        let result = NSMutableDictionary()
        result.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        result.setValue(key, forKey: kSecAttrAccount as String)
        result.setValue(service, forKey: kSecAttrService as String)
        result.setValue(accessGroup, forKey: kSecAttrAccessGroup as String)
        return result
    }
}
