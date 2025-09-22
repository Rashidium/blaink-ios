//
//  SSLPinningManager.swift
//  API
//
//  Prompted by Raşid Ramazanov using Cursor on 31.01.2025.
//

import CommonCrypto
import Foundation
import Security

final class SSLPinningManager: NSObject {
    static let shared = SSLPinningManager()

    //  key hashes for blainks.com (SHA256)
    // These should be updated with the actual certificate hashes from your server
    private let pinnedPublicKeyHashes: Set<String> = [
        // Primary certificate hash - you'll need to get the actual hash from your server
        "dadd573a382d50811225f8d48bff35e536c33fbee1da16a0b420aca3ba730472",
        // Backup certificate hash (optional)
        "56a78fc47dc4705c19b982b708238ccf91ca32878866965c13205fe1d88f1920"
    ]

    // Domains that require SSL pinning
    private let pinnedDomains: Set<String> = [
        "blainks.com",
        "api.blainks.com",
        "www.blainks.com"
    ]

    override private init() {
        super.init()
    }

    // MARK: - Certificate Validation

    func validateCertificateChain(
        for challenge: URLAuthenticationChallenge
    ) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host.components(separatedBy: ":").first else {
            return (.performDefaultHandling, nil)
        }

        // Check if this domain requires pinning
        guard pinnedDomains.contains(host) else {
            return (.performDefaultHandling, nil)
        }

        // Perform certificate chain validation
        guard validateServerTrust(serverTrust, for: host) else {
            #if DEBUG
            print("🔐 SSL Pinning: Certificate validation failed for \(host)")
            #endif
            return (.cancelAuthenticationChallenge, nil)
        }

        #if DEBUG
        print("🔐 SSL Pinning: Certificate validation succeeded for \(host)")
        #endif

        return (.useCredential, URLCredential(trust: serverTrust))
    }

    private func validateServerTrust(_ serverTrust: SecTrust, for host: String) -> Bool {
        // Set the hostname for validation
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        // Evaluate the trust
        var error: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)

        guard isTrusted else {
            return false
        }

        // Validate pinned keys
        return validatePinnedPublicKeys(serverTrust)
    }

    private func validatePinnedPublicKeys(_ serverTrust: SecTrust) -> Bool {
        // iOS 15+ → tüm zinciri tek seferde al
        guard let certs = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return false
        }

        for cert in certs {
            if let hash = getPublicKeyHash(from: cert),
               pinnedPublicKeyHashes.contains(hash) {
                return true
            }
        }
        return false
    }

    private func getPublicKeyHash(from certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
            return nil
        }

        let data = publicKeyData as Data
        return data.sha256Hash
    }
}

// MARK: - URLSessionDelegate

extension SSLPinningManager: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let (disposition, credential) = validateCertificateChain(for: challenge)
        completionHandler(disposition, credential)
    }
}

// MARK: - Data Extension for Hashing

private extension Data {
    var sha256Hash: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Certificate Hash Extraction Utility

#if DEBUG
extension SSLPinningManager {
    /// Helper method to extract certificate hashes for development/testing
    /// This should not be used in production
    static func extractCertificateHashes(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { _, response, _ in
            guard let httpResponse = response as? HTTPURLResponse,
                  let url = httpResponse.url,
                  let host = url.host else {
                return
            }

            print("🔍 Certificate hashes for \(host):")
            print("Add these to your pinnedPublicKeyHashes array:")
        }
        task.resume()
    }
}
#endif
