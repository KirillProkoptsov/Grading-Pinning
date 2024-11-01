//
//  KeyPinnedAFSessionManager.swift
//  Grading-Pinning
//
//  Created by Prokoptsov on 05.08.2024.
//

import Foundation
import Alamofire

final class KeyPinnedAFSessionManager {

	// MARK: - Private properties

	private let certificatesInfo: [(String, String)]

	private let publicKeys: [SecKey]

	// MARK: - Init

	init(certificatesInfo: [(String, String)]) {
		self.certificatesInfo = certificatesInfo
		self.publicKeys = certificatesInfo.compactMap {
			guard let url = Bundle.main.url(forResource: $0.0, withExtension: $0.1),
						let certificateData = try? Data(contentsOf: url),
						let publicKey = KeyPinnedAFSessionManager.extractPublicKey(from: certificateData) else { return nil }
			return publicKey
		}
	}

	// MARK: - Internal methods

	func makeSession() -> Session {
		let serverTrustManager = ServerTrustManager(
			allHostsMustBeEvaluated: false,
			evaluators: [certificatesInfo.first?.0 ?? "": PublicKeysTrustEvaluator(keys: publicKeys)]
		)

		let configuration = URLSessionConfiguration.af.default

		return Session(configuration: configuration, serverTrustManager: serverTrustManager)
	}

	// MARK: - Private methods

	// Метод для извлечения публичного ключа из данных сертификата
	private static func extractPublicKey(from certificateData: Data) -> SecKey? {
		guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else { return nil }

		var trust: SecTrust?
		SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
		return SecTrustCopyKey(trust!)
	}
}
