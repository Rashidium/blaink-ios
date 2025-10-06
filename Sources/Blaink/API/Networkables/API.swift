//
//  API.swift
//  API
//
//  Created by Rashid Ramazanov on 10/19/22.
//  Copyright © 2022 Mobven. All rights reserved.
//

import Foundation

enum API {
    static let isLocal: Bool = false
    static var baseURL: String {
        if isLocal {
            "http://192.168.1.114:5432/"
        } else {
            "https://blainks.com/"
        }
    }

    static func prepareURL(withPath path: String) -> URL {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            fatalError("Could not prepare url")
        }
        return url
    }
}
