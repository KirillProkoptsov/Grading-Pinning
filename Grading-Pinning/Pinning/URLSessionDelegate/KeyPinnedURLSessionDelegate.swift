//
//  KeyPinnedURLSessionDelegate.swift
//  Grading-Pinning
//
//  Created by Prokoptsov on 19.07.2024.
//

import Foundation
import Security

final class KeyPinnedURLSessionDelegate: NSObject, URLSessionDelegate {

	// MARK: - Private properties

	private let pinnedPublicKeys: [Data]

	// MARK: - Init

	init(publicKeyInfo: [(String, String)]) {
		self.pinnedPublicKeys = publicKeyInfo.compactMap {
			guard let url = Bundle.main.url(forResource: $0.0, withExtension: $0.1),
						let certificateData = try? Data(contentsOf: url),
						let keyData = KeyPinnedURLSessionDelegate.extractPublicKey(from: certificateData) else { return nil }
			return keyData
		}
	}

	// MARK: - URLSessionDelegate

	func urlSession(
		_ session: URLSession,
		didReceive challenge: URLAuthenticationChallenge,
		completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
	) {
		if let trust = challenge.protectionSpace.serverTrust,
			 let certificates = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
			 !certificates.isEmpty {
			certificates.forEach { cert in
				let certificateData = SecCertificateCopyData(cert) as Data
				if let publicKeyData = KeyPinnedURLSessionDelegate.extractPublicKey(from: certificateData),
					 pinnedPublicKeys.contains(publicKeyData) {
					completionHandler(.useCredential, URLCredential(trust: trust))
					return
				}
			}
		}
		completionHandler(.cancelAuthenticationChallenge, nil)
	}

	// MARK: - Private methods

	private static func extractPublicKey(from certificateData: Data) -> Data? {
		guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else { return nil }
		var trust: SecTrust?

		SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)

		guard let trust,
					let publicKey = SecTrustCopyKey(trust) else { return nil }

		var error: Unmanaged<CFError>?

		guard let keyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
			print("extractPublicKey: Error: \(String(describing: error))")
			return nil
		}
		return keyData
	}
}
