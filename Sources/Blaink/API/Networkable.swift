import Combine
import Foundation

protocol Networkable {
    func request() async -> URLRequest
}

extension Networkable {
    func get(queryItems: [String: String] = [:], path: String, addBearerToken: Bool = true) async -> URLRequest {
        await prepareRequest(
            withPath: path,
            queryItems: queryItems,
            method: .get,
            contentType: .json,
            addBearerToken: addBearerToken
        )
    }

    func post(
        body: some Encodable, path: String, headers: [String: String] = [:], addBearerToken: Bool = true
    ) async -> URLRequest {
        var request = await prepareRequest(
            withPath: path,
            method: .post,
            contentType: .json,
            headers: headers,
            addBearerToken: addBearerToken
        )
        request.httpBody = getBody(body)
        return request
    }

    func put(
        body: some Encodable, path: String, headers: [String: String] = [:], addBearerToken: Bool = true
    ) async -> URLRequest {
        var request = await prepareRequest(
            withPath: path,
            method: .put,
            contentType: .json,
            headers: headers,
            addBearerToken: addBearerToken
        )
        request.httpBody = getBody(body)
        return request
    }

    func delete(body: some Encodable, path: String, addBearerToken: Bool = true) async -> URLRequest {
        var request = await delete(path: path, addBearerToken: addBearerToken)
        request.httpBody = getBody(body)
        return request
    }

    func delete(path: String, addBearerToken: Bool = true) async -> URLRequest {
        let request = await prepareRequest(
            withPath: path,
            method: .delete,
            contentType: .json,
            addBearerToken: addBearerToken
        )
        return request
    }

    private func getBody(_ body: some Encodable) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(body)
    }

    func uploadRequest(
        method: RequestMethod = .post,
        path: String,
        parameters: [String: String] = [:],
        files: [File] = [],
        headers: [String: String] = [:],
        addBearerToken: Bool = true
    ) async -> URLRequest {
        var body = Data()
        let boundary = "Boundary-\(UUID().uuidString)"
        let lineBreak = "\r\n"
        let boundaryPrefix = "--\(boundary)\(lineBreak)"
        var timeout = 0.0

        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
            body.appendString("\(value)\(lineBreak)")
        }

        for file in files {
            body.appendString(boundaryPrefix)
            body.appendString(
                "Content-Disposition: form-data; name=\"\(file.name)\";" +
                    "filename=\"\(file.fileNameWithExtension)\"\(lineBreak)"
            )
            body.appendString("Content-Type: \(file.mimeType)\(lineBreak + lineBreak)")
            body.append(file.data)
            body.appendString("\(lineBreak)")
            timeout += Double(file.data.count) * 0.00005
        }
        // if file size is small, there should be a treshold for upload.
        // smaller files reproduces timeout on network.
        if timeout < 30 {
            timeout = 30
        }
        body.appendString("--".appending(boundary.appending("--")))
        var request = await prepareRequest(
            withPath: path,
            method: .post,
            contentType: .multipartFormData(boundary),
            headers: headers,
            addBearerToken: addBearerToken
        )
        request.httpBody = body as Data
        request.timeoutInterval = timeout
        request.httpMethod = method.rawValue
        return request
    }

    private func prepareRequest(
        withPath path: String,
        queryItems: [String: String] = [:],
        method: RequestMethod,
        contentType: NetworkContentType,
        headers: [String: String] = [:],
        addBearerToken: Bool = true
    ) async -> URLRequest {
        let url = API.prepareURL(withPath: path).adding(parameters: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        var headers = headers
        headers.updateValue(contentType.rawValue, forKey: "Content-Type")

        if addBearerToken {
            let token = try? await OAuthManager.shared.authManager.validToken()
            if token == true {
                headers.updateValue("Bearer \(UserSession.shared.accessToken ?? "")", forKey: "Authorization")
            }
        }
        request.allHTTPHeaderFields = headers
        return request
    }
}

extension Networkable {
    func fetch<T: Decodable>(
        responseModel model: T.Type,
        hasAuthentication: Bool = true,
        isRefreshToken: Bool = false
    ) async -> Result<T, Error> {
        do {
            let (data, response) = try await PinnedURLSession.shared.data(for: request())
            guard let response = response as? HTTPURLResponse else {
                return .failure(NSError.generic)
            }

            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                if PinnedURLSession.shared.isDebugLogsEnabled {
                    #if DEBUG
                    print("\n\n\n---Networking---")
                    let req = await request()
                    print(req.url?.absoluteString ?? "")
                    if let body = req.httpBody {
                        print(String(decoding: body, as: UTF8.self))
                    }
                    print(String(decoding: jsonData, as: UTF8.self))
                    print("---Networking---\n\n\n")
                    #endif
                }
            }

            switch response.statusCode {
            case 401:
                if hasAuthentication {
                    if !isRefreshToken, try await OAuthManager.shared.authManager.refreshToken() {
                        return await fetch(
                            responseModel: model,
                            hasAuthentication: hasAuthentication,
                            isRefreshToken: isRefreshToken
                        )
                    } else {
                        UserSession.clear()
                        return .failure(NSError.generic)
                    }
                } else {
                    return .failure(NSError.generic)
                }
            default:
                if model.self is Data.Type {
                    // swiftlint:disable force_cast
                    return .success(data as! T)
                    // swiftlint:enable force_cast
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(Response<T>.self, from: data)
                if let body = decodedResponse.body {
                    return .success(body)
                } else {
                    return .failure(NSError.generic)
                }
            }
        } catch {
            return .failure(NSError.generic)
        }
    }
}

extension NSError {
    static var generic: NSError {
        .init(domain: "com.blainks", code: 400, userInfo: nil)
    }
}
