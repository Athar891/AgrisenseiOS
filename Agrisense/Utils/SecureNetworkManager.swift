//
//  SecureNetworkManager.swift
//  Agrisense
//
//  Created by Security Audit on 01/10/25.
//

import Foundation
import Security

// MARK: - Certificate Pinning

/// Secure network manager with SSL certificate pinning
class SecureNetworkManager: NSObject {
    static let shared = SecureNetworkManager()
    
    // Certificate hashes for pinning (SHA-256)
    // TODO: Update these with your actual certificate hashes
    private let pinnedCertificateHashes: Set<String> = [
        // Firebase certificate hash (example - replace with actual)
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        // Cloudinary certificate hash (example - replace with actual)
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
        // OpenWeather API certificate hash (example - replace with actual)
        "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
    ]
    
    private override init() {
        super.init()
    }
    
    // MARK: - URLSession with Certificate Pinning
    
    /// Create a URLSession with certificate pinning enabled
    func createSecureSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    // MARK: - Certificate Validation
    
    private func validateServerTrust(_ serverTrust: SecTrust, for host: String) -> Bool {
        // Get server certificate chain
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            #if DEBUG
            print("[SecureNetworkManager] Failed to get server certificate")
            #endif
            return false
        }
        
        // Get certificate data
        let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data
        
        // Calculate SHA-256 hash
        let certificateHash = sha256Hash(data: serverCertificateData)
        
        #if DEBUG
        print("[SecureNetworkManager] Server certificate hash: \(certificateHash)")
        print("[SecureNetworkManager] Validating against pinned hashes...")
        #endif
        
        // Check if certificate hash matches pinned hashes
        if pinnedCertificateHashes.contains(certificateHash) {
            #if DEBUG
            print("[SecureNetworkManager] ✅ Certificate validation successful")
            #endif
            return true
        }
        
        #if DEBUG
        print("[SecureNetworkManager] ❌ Certificate validation failed - hash not in pinned set")
        print("[SecureNetworkManager] Expected one of: \(pinnedCertificateHashes)")
        #endif
        
        return false
    }
    
    private func sha256Hash(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
}

// MARK: - URLSessionDelegate

extension SecureNetworkManager: URLSessionDelegate {
    
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
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        #if DEBUG
        print("[SecureNetworkManager] Validating certificate for host: \(host)")
        #endif
        
        // Validate server trust
        if validateServerTrust(serverTrust, for: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            #if DEBUG
            print("[SecureNetworkManager] Certificate pinning failed for host: \(host)")
            #endif
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - CommonCrypto Import

import CommonCrypto

// MARK: - Certificate Pinning Helper

extension SecureNetworkManager {
    
    /// Extract certificate hash from a certificate file in the bundle
    /// Use this during development to get the certificate hash
    static func getCertificateHash(from filename: String) -> String? {
        guard let certificatePath = Bundle.main.path(forResource: filename, ofType: "cer"),
              let certificateData = try? Data(contentsOf: URL(fileURLWithPath: certificatePath)) else {
            print("[SecureNetworkManager] Failed to load certificate: \(filename)")
            return nil
        }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        certificateData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(certificateData.count), &hash)
        }
        
        let hashString = Data(hash).base64EncodedString()
        print("[SecureNetworkManager] Certificate hash for \(filename): \(hashString)")
        return hashString
    }
    
    /// Disable certificate pinning for development/testing
    /// WARNING: Only use this for development, never in production
    static var isPinningEnabled: Bool {
        #if DEBUG
        return false // Disabled in debug builds for easier testing
        #else
        return true // Always enabled in production
        #endif
    }
}

// MARK: - Usage Example (Comment out in production)

/*
 
 HOW TO USE CERTIFICATE PINNING:
 
 1. Get your server's certificate:
    - For Firebase: Download from Firebase Console
    - For Cloudinary: Use openssl to get certificate
    - For OpenWeather: Use openssl to get certificate
 
 2. Extract certificate hash:
    ```
    openssl s_client -servername api.cloudinary.com -connect api.cloudinary.com:443 < /dev/null | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64
    ```
 
 3. Update pinnedCertificateHashes with real hashes
 
 4. Use SecureNetworkManager for network requests:
    ```swift
    let session = SecureNetworkManager.shared.createSecureSession()
    let task = session.dataTask(with: url) { data, response, error in
        // Handle response
    }
    task.resume()
    ```
 
 5. For development, you can temporarily disable pinning by setting isPinningEnabled to false
 
 */
