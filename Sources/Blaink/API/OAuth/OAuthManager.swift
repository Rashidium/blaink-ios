//
//  OAuthManager.swift
//  API
//
//  Created by Rashid Ramazanov on 24.01.2023.
//

import Foundation

class OAuthManager {
    static let shared: OAuthManager = .init()
    var authManager: OAuthProvider = .init()
}
