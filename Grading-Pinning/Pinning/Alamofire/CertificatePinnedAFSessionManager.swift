//
//  CertificatePinnedAFSessionManager.swift
//  Grading-Pinning
//
//  Created by Prokoptsov on 05.08.2024.
//

import Foundation
import Alamofire

final class CertificatePinnedAFSessionManager {

	// MARK: - Private properties

	private let certificatesInfo: [(String, String)]
	private let certificates: [Data]

	// MARK: - Init

	init(certificatesInfo: [(String, String)]) {
		self.certificatesInfo = certificatesInfo
		self.certificates = certificatesInfo.compactMap {
			guard let url = Bundle.main.url(forResource: $0.0, withExtension: $0.1),
						let data = try? Data(contentsOf: url) else { return nil }
			return data
		}
	}

	// MARK: - Internal methods

	func makeSession() -> Session {
		let secCertificates: [SecCertificate] = certificates.compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }

		let serverTrustManager = ServerTrustManager(
			allHostsMustBeEvaluated: false,
			evaluators: [certificatesInfo.first?.0 ?? "": PinnedCertificatesTrustEvaluator(certificates: secCertificates)]
		)
		let configuration = URLSessionConfiguration.af.default

		return Session(configuration: configuration, serverTrustManager: serverTrustManager)
	}
}
