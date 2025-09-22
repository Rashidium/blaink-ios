//
//  OAuthProvider.swift
//  API
//
//  Created by Rashid Ramazanov on 24.01.2023.
//

import Foundation

actor OAuthProvider {
    private var refreshTask: Task<Bool, Error>?
    func validToken() async throws -> Bool {
        if let handle = refreshTask {
            return try await handle.value
        }

        guard let token = UserSession.shared.accessToken else {
            return try await refreshToken()
        }

        if !token.isEmpty {
            return true
        }

        return try await refreshToken()
    }

    func refreshToken() async throws -> Bool {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task { () throws -> Bool in
            defer { refreshTask = nil }

            let result = await API.AUTH.refresh.fetch(
                responseModel: ClientResponse.self,
                hasAuthentication: true,
                isRefreshToken: true
            )
            switch result {
            case let .success(response):
                UserSession.shared.accessToken = response.accessToken
                UserSession.shared.refreshToken = response.refreshToken
                return true
            case .failure:
                throw AuthError.missingToken
            }
        }

        refreshTask = task

        return try await task.value
    }
}
