//
//  dasd.swift
//  Grading-Pinning
//
//  Created by Prokoptsov on 19.07.2024.
//

import Foundation
import Alamofire

// MARK: - PinningType

enum PinningType: Int, CaseIterable {
	case certificatePinnedSession
	case keyPinnedSession
	case certificatePinnedAlamofire
	case keyPinnedAlamofire
	
	var title: String {
		switch self {
		case .certificatePinnedSession:
			return "Cert(Session)"
		case .keyPinnedSession:
			return "Кey(Session)"
		case .certificatePinnedAlamofire:
			return "Cert(AF)"
		case .keyPinnedAlamofire:
			return "Key(AF)"
		}
	}
}

// MARK: - PinningType: Sessions

extension PinningType {
	
	var urlSession: URLSession? {
		switch self {
		case .certificatePinnedSession, .keyPinnedSession:
			return URLSession(
				configuration: configuration,
				delegate: sessionDelegate,
				delegateQueue: nil
			)
		default:
			return nil
		}
	}
	
	var AFSession: Session? {
		switch self {
		case .certificatePinnedAlamofire:
			return CertificatePinnedAFSessionManager(certificatesInfo: certificatesInfo).makeSession()
		case .keyPinnedAlamofire:
			return KeyPinnedAFSessionManager(certificatesInfo: certificatesInfo).makeSession()
		default:
			return nil
		}
	}
	
	// MARK: - Private properties
	
	private var certificatesInfo: [(String, String)] {
		[
			(name: "jsonplaceholder.typicode.com", type: "cer")
		]
	}
	
	private var sessionDelegate: URLSessionDelegate? {
		switch self {
		case .certificatePinnedSession:
			return CertificatePinnedURLSessionDelegate(certificateInfo: certificatesInfo)
		case .keyPinnedSession:
			return KeyPinnedURLSessionDelegate(publicKeyInfo: certificatesInfo)
		default:
			return nil
		}
	}
	
	private var configuration: URLSessionConfiguration {
		let configuration = URLSessionConfiguration.default
		configuration.waitsForConnectivity = true
		configuration.timeoutIntervalForRequest = 10
		configuration.timeoutIntervalForResource = 15
		configuration.urlCache = nil
		return configuration
	}
}
