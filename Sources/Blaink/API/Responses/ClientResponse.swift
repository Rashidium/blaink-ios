//
//  ClientResponse.swift
//
//
//  Created by Cihan Canik on 6.11.2022.
//

import Foundation

struct ClientResponse: Codable {
    let id: String
    let accessToken: String
    let refreshToken: String
}
