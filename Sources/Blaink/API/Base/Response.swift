//
//  Response.swift
//  Commune
//
//  Created by Rashid Ramazanov on 8/5/22.
//

import Foundation

struct Response<T: Decodable>: Decodable {
    var error: Bool
    var reason: String?
    var body: T?
}
