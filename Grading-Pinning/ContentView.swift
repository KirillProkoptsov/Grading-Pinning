//
//  ContentView.swift
//  Grading-Pinning
//
//  Created by Prokoptsov on 19.07.2024.
//

import Alamofire
import SwiftUI

struct ContentView: View {

	// MARK: - Private properties

	private let requestURL: URL = .init(string: "https://jsonplaceholder.typicode.com/photos")!

	@State private var backgroundColor: Color = .white
	@State private var isLoading: Bool = false
	@State private var selectedPinningType: PinningType = .certificatePinnedSession
	@State private var error: AlertError?

	// MARK: - Internal UI properties

	var body: some View {
		typePicker
			.safeAreaPadding()
		content
			.overlay {
				if isLoading {
					ProgressView()
						.controlSize(.extraLarge)
				}
			}
			.alert(item: $error) { error in
				Alert(
					title: Text("Error"),
					message: Text(error.message),
					dismissButton: .default(Text("Close"), action: {
						self.error = nil
					})
				)
			}
			.onChange(of: selectedPinningType) {
				backgroundColor = .white
			}
	}

	// MARK: - Private UI properties

	private var typePicker: some View {
		Picker("", selection: $selectedPinningType) {
			ForEach(PinningType.allCases, id: \.self) { item in
				Text(item.title)
			}
		}
		.pickerStyle(.segmented)
	}

	private var content: some View {
		VStack {
			Button(action: {
				Task {
					switch selectedPinningType {
					case .certificatePinnedSession, .keyPinnedSession:
						guard let session = selectedPinningType.urlSession else { return }
						await makeNetworkRequest(with: session)
					case .certificatePinnedAlamofire, .keyPinnedAlamofire:
						guard let AFSession = selectedPinningType.AFSession else { return }
						await makeNetworkRequest(with: AFSession)
					}
				}
			}, label: {
				Image(systemName: "network")
					.imageScale(.large)
					.foregroundStyle(.tint)
				Text("Send request")
			})
		}
		.padding()
		.background(backgroundColor)
		.cornerRadius(10)
	}

	// MARK: - Business logic

	@MainActor
	private func makeNetworkRequest(with session: URLSession) async {
		defer {
			self.isLoading = false
		}
		self.backgroundColor = .white
		self.isLoading = true
		do {
			_ = try await session.data(for: URLRequest(url: requestURL))
			self.backgroundColor = .green
		} catch {
			self.backgroundColor = .red
			self.error = .init(message: error.localizedDescription)
		}
	}

	@MainActor
	private func makeNetworkRequest(with session: Session) async {
		defer {
			self.isLoading = false
		}
		self.backgroundColor = .white
		self.isLoading = true
		do {
			_ = try await makeAFRequest(requestURL, session)
			self.backgroundColor = .green
		} catch {
			self.backgroundColor = .red
			self.error = .init(message: error.localizedDescription)
		}
	}

	private func makeAFRequest(_ url: URL, _ session: Session) async throws -> Void {
		return try await withCheckedThrowingContinuation { continuation in
			session.request(url)
				.responseData { response in
					switch response.result {
					case .success:
						continuation.resume(returning: Void())
					case .failure(let error):
						continuation.resume(throwing: error)
					}
				}
		}
	}
}

// MARK: - AlertError

private struct AlertError: Identifiable {
	let id = UUID()
	let message: String
}
