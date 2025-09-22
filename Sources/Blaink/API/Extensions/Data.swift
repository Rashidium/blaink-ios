//
//  Data.swift
//
//
//  Created by Fatih on 9.12.2022.
//

import Foundation

extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
