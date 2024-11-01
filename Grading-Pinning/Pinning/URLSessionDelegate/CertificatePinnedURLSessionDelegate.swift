//
//  CertificatePinnedURLSessionDelegate.swift
//  Grading-Safety
//
//  Created by Prokoptsov on 19.07.2024.
//

import Foundation

final class CertificatePinnedURLSessionDelegate: NSObject, URLSessionDelegate {

	// MARK: - Private properties

	private let certificates: [Data]

	// MARK: - Init

	init(certificateInfo: [(String, String)]) {
		self.certificates = certificateInfo.compactMap {
			guard let url = Bundle.main.url(forResource: $0.0, withExtension: $0.1),
						let data = try? Data(contentsOf: url) else { return nil }
			return data
		}
	}

	// MARK: - URLSessionDelegate

	func urlSession(
		_ session: URLSession,
		didReceive challenge: URLAuthenticationChallenge,
		completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
	) {
		if let trust = challenge.protectionSpace.serverTrust,
			 SecTrustGetCertificateCount(trust) > 0 {
			if let serverCertificate = (SecTrustCopyCertificateChain(trust) as? [SecCertificate])?.first {
				let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data
				if certificates.contains(serverCertificateData) {
					completionHandler(.useCredential, URLCredential(trust: trust))
					return
				} else {
					print("Certificate mismatch")
				}
			}
		}
		completionHandler(.cancelAuthenticationChallenge, nil)
	}
}
