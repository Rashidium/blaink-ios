//
//  PinnedURLSession.swift
//  API
//
//  Prompted by Raşid Ramazanov using Cursor on 31.01.2025.
//

import Foundation

final class PinnedURLSession {
    static let shared = PinnedURLSession()
    var isDebugLogsEnabled: Bool = false

    /// URLSession configured with SSL pinning for HTTP requests
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0

        return URLSession(
            configuration: configuration,
            delegate: SSLPinningManager.shared,
            delegateQueue: nil
        )
    }()

    /// URLSession configured with SSL pinning for WebSocket connections
    lazy var webSocketSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0

        return URLSession(
            configuration: configuration,
            delegate: SSLPinningManager.shared,
            delegateQueue: nil
        )
    }()

    private init() {}

    // MARK: - Convenience Methods

    /// Perform a data request with SSL pinning
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }

    /// Create a WebSocket task with SSL pinning
    func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTask {
        webSocketSession.webSocketTask(with: request)
    }

    /// Create a WebSocket task with URL and SSL pinning
    func webSocketTask(with url: URL) -> URLSessionWebSocketTask {
        webSocketSession.webSocketTask(with: url)
    }
}
