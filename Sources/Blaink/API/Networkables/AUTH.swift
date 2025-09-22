//
//  AUTH.swift
//  API
//
//  Created by Rashid Ramazanov on 10/19/22.
//  Copyright © 2022 Mobven. All rights reserved.
//

import Foundation

extension API {
    enum AUTH: Networkable {
        case initSdk(request: ClientRequest)
        case refresh
        case update(request: UpdateUserRequest)
        case profilePhoto(file: File)
        case me
        case logout
        case deleteAccount

        // swiftlint:disable cyclomatic_complexity
        func request() async -> URLRequest {
            switch self {
            case let .initSdk(request):
                return await post(
                    body: request,
                    path: "api/v1/client/init",
                    headers: basicHeaders(),
                    addBearerToken: false
                )
            case .refresh:
                var request = await get(path: "api/v1/client/refresh", addBearerToken: false)
                if request.allHTTPHeaderFields == nil {
                    request.allHTTPHeaderFields = [:]
                }
                request.allHTTPHeaderFields?.updateValue(
                    UserSession.shared.refreshToken ?? "",
                    forKey: "Authorization"
                )
                return request
            case let .update(request):
                return await put(body: request, path: "api/v1/client/me")
            case let .profilePhoto(file):
                return await uploadRequest(
                    path: "api/v1/client/me/uploadProfilePhoto",
                    parameters: ["filename": file.fileNameWithExtension],
                    files: [file]
                )
            case .me:
                return await get(path: "api/v1/client/me")
            case .logout:
                return await get(path: "api/v1/client/logout")
            case .deleteAccount:
                return await delete(path: "api/client/me")
            }
        }

        private func basicHeaders() -> [String: String] {
            let username = "Blaink"
            let password = "Blaink!@2025"
            let loginString = "\(username):\(password)"

            guard let loginData = loginString.data(using: .utf8) else {
                return [:]
            }

            let base64LoginString = loginData.base64EncodedString()

            return ["Authorization": "Basic \(base64LoginString)"]
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
