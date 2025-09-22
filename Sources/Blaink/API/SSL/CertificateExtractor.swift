//
//  CertificateExtractor.swift
//  API
//
//  Prompted by Raşid Ramazanov using Cursor on 31.01.2025.
//

import CommonCrypto
import Foundation
import Security

#if DEBUG
enum CertificateExtractor {
    static func extractCertificateHashes(from domain: String, completion: @escaping ([String]) -> Void) {
        guard let url = URL(string: "https://\(domain)") else {
            print("❌ Invalid URL for domain: \(domain)")
            completion([])
            return
        }

        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let error {
                print("❌ Error connecting to \(domain): \(error.localizedDescription)")
                completion([])
                return
            }

            // The response itself doesn't contain the certificate chain
            // We need to use a different approach with URLSessionDelegate
            print("ℹ️  To extract certificate hashes, we need to perform a dedicated SSL handshake")
            extractCertificatesUsingSSLHandshake(domain: domain, completion: completion)
        }
        task.resume()
    }

    private static func extractCertificatesUsingSSLHandshake(domain: String, completion: @escaping ([String]) -> Void) {
        let delegate = CertificateExtractionDelegate { hashes in
            completion(hashes)
        }

        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)

        guard let url = URL(string: "https://\(domain)") else {
            completion([])
            return
        }

        let task = session.dataTask(with: url) { _, _, _ in
            // We don't care about the response data, just the certificate chain
        }
        task.resume()
    }

    static func printInstructions() {
        print("""

        🔐 SSL Pinning Setup Instructions:

        1. Run the following command to extract certificate hashes:
           CertificateExtractor.extractCertificateHashes(from: "blainks.com") { hashes in
               print("Certificate hashes: \\(hashes)")
           }

        2. Replace the placeholder hashes in SSLPinningManager with the actual hashes

        3. Test your SSL pinning implementation thoroughly

        4. Consider pinning multiple certificates (primary + backup) for certificate rotation

        """)
    }
}

private final class CertificateExtractionDelegate: NSObject, @unchecked Sendable, URLSessionDelegate {
    private let completion: ([String]) -> Void

    init(completion: @escaping ([String]) -> Void) {
        self.completion = completion
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        var hashes: [String] = []
        let certificateCount = SecTrustGetCertificateCount(serverTrust)

        print("🔍 Found \(certificateCount) certificates in the chain for \(challenge.protectionSpace.host)")

        for i in 0 ..< certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }

            if let hash = getPublicKeyHash(from: certificate) {
                hashes.append(hash)
                print("📜 Certificate \(i): \(hash)")

                // Print certificate details
                if let summary = SecCertificateCopySubjectSummary(certificate) {
                    print("   Subject: \(summary)")
                }
            }
        }

        print("\n✅ Add these hashes to your SSLPinningManager:")
        print("private let pinnedPublicKeyHashes: Set<String> = [")
        for hash in hashes {
            print("    \"\(hash)\",")
        }
        print("]")

        completion(hashes)

        // Allow the connection to proceed for extraction purposes
        completionHandler(.performDefaultHandling, nil)
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

private extension Data {
    var sha256Hash: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash).map { String(format: "%02x", $0) }.joined()
    }
}
#endif
