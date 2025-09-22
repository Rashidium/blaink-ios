//
//  Savable.swift
//  Storage
//
//  Created by Rashid Ramazanov on 1/11/23.
//

import Foundation

protocol DataSavable {
    subscript(_: String) -> String? { get set }
    func save(_ value: (some Encodable)?, forKey key: String)
    func get<V: Decodable>(forKey key: String) -> V?
}
