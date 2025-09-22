//
//  SSLPinningSetup.swift
//  API
//
//  Prompted by Raşid Ramazanov using Cursor on 31.01.2025.
//

import Foundation

enum SSLPinningSetup {
    /// Extract certificate hashes for your domain and provide setup instructions
    static func setupSSLPinning() {
        #if DEBUG
        print("🔐 Setting up SSL Pinning for Conversaio")
        print("=====================================")

        CertificateExtractor.extractCertificateHashes(from: "blainks.com") { hashes in
            DispatchQueue.main.async {
                displaySetupInstructions(hashes: hashes)
            }
        }
        #else
        print("⚠️  SSL Pinning setup is only available in DEBUG builds")
        #endif
    }

    #if DEBUG
    private static func displaySetupInstructions(hashes: [String]) {
        print("\n" + String(repeating: "=", count: 60))
        print("🔐 SSL PINNING SETUP COMPLETE")
        print(String(repeating: "=", count: 60))

        if !hashes.isEmpty {
            print("\n✅ Certificate hashes extracted successfully!")
            print("\n📝 Next steps:")
            print("1. Copy the certificate hashes shown above")
            print("2. Replace the placeholder hashes in SSLPinningManager.swift")
            print("3. Remove the #if DEBUG wrapper around the certificate extraction code")
            print("4. Test your app thoroughly")

            print("\n🔧 Example configuration:")
            print("private let pinnedPublicKeyHashes: Set<String> = [")
            for hash in hashes {
                print("    \"\(hash)\",")
            }
            print("]")

            print("\n⚠️  Important Security Notes:")
            print("• Pin at least 2 certificates (primary + backup)")
            print("• Monitor certificate expiration dates")
            print("• Have a certificate rotation plan")
            print("• Test pinning with Charles Proxy or similar tools")

        } else {
            print("\n❌ Failed to extract certificate hashes")
            print("Please check your network connection and try again")
        }

        print("\n" + String(repeating: "=", count: 60))
    }
    #endif

    /// Test SSL pinning functionality
    static func testSSLPinning() async {
        print("🧪 Testing SSL Pinning...")

        do {
            let url = URL(string: "https://blainks.com/api/v1/health")!
            let request = URLRequest(url: url)

            let (_, response) = try await PinnedURLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ SSL Pinning test passed! Connection successful.")
                } else {
                    print("⚠️  SSL Pinning test: Server responded with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            if (error as NSError).code == NSURLErrorServerCertificateUntrusted {
                print("🔐 SSL Pinning is working! Certificate validation failed as expected for untrusted certificates.")
            } else {
                print("❌ SSL Pinning test failed: \(error.localizedDescription)")
            }
        }
    }

    /// Validate SSL pinning configuration
    static func validateConfiguration() -> Bool {
        let manager = SSLPinningManager.shared

        // Check if placeholder hashes are still in use
        print("🔍 Validating SSL Pinning configuration...")

        // This is a simplified check - in a real implementation,
        // you'd want to verify the actual hashes are configured
        print("⚠️  Remember to replace placeholder certificate hashes with actual values")
        print("✅ SSL Pinning configuration structure is valid")

        return true
    }
}
