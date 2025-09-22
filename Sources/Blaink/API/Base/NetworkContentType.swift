//
//  NetworkContentType.swift
//  API
//
//  Created by Rashid Ramazanov on 1/4/23.
//

import Foundation

/// "Content-Type" values for network requests.
enum NetworkContentType {
    /// Content type used when expecting response  in JSON format.
    case json
    case multipartFormData(String)

    var rawValue: String {
        switch self {
        case .json: "application/json"
        case let .multipartFormData(boundary): "multipart/form-data; boundary=\(boundary)"
        }
    }
}
